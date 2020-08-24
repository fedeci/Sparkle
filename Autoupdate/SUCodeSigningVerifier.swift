//
//  SUCodeSigningVerifier.swift
//  Autoupdate
//
//  Created by Federico Ciardi on 09/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation
import Security.CodeSigning
import Security.SecCode

class SUCodeSigningVerifier: NSObject {
    static func codeSignature(atBundleURL oldBundleURL: URL, matchesSignatureAtBundleURL newBundleURL: URL) throws -> Bool {
        
        var result: OSStatus
        
        var oldCode: SecStaticCode?
        result = SecStaticCodeCreateWithPath(oldBundleURL as CFURL, [], &oldCode)
        guard result != errSecCSUnsigned, oldCode != nil else { return false }
        
        var requirement: SecRequirement?
        result = SecCodeCopyDesignatedRequirement(oldCode!, [], &requirement)
        guard result == noErr, requirement != nil else {
            SULog(.error, "Failed to copy designated requirement. Code Signing OSStatus code: \(result)")
            return false
        }
        
        var staticCode: SecStaticCode?
        result = SecStaticCodeCreateWithPath(newBundleURL as CFURL, [], &staticCode)
        guard result == noErr, staticCode != nil else {
            SULog(.error, "Failed to get static code \(result)")
            return false
        }
        
        // Note that kSecCSCheckNestedCode may not work with pre-Mavericks code signing.
        // See https://github.com/sparkle-project/Sparkle/issues/376#issuecomment-48824267 and https://developer.apple.com/library/mac/technotes/tn2206
        // Aditionally, there are several reasons to stay away from deep verification and to prefer DSA signing the download archive instead.
        // See https://github.com/sparkle-project/Sparkle/pull/523#commitcomment-17549302 and https://github.com/sparkle-project/Sparkle/issues/543
        var cfError: Unmanaged<CFError>?
        let flags = SecCSFlags(rawValue: (0 | kSecCSCheckAllArchitectures))
        // swiftlint:disable:next force_unwrapping
        result = SecStaticCodeCheckValidityWithErrors(staticCode!, flags, requirement, &cfError)
        
        if let tmpError = cfError?.takeUnretainedValue() as? NSError {
            cfError?.release()
            throw tmpError
        }
        
        if result != noErr {
            if result == errSecCSUnsigned {
                SULog(.error, "The host app is signed, but the new version of the app is not signed using Apple Code Signing. Please ensure that the new app is signed and that archiving did not corrupt the signature.")
            }
            if result == errSecCSReqFailed {
                var requirementString: CFString?
                // swiftlint:disable:next force_unwrapping
                if SecRequirementCopyString(requirement!, [], &requirementString) == noErr {
                    SULog(.error, "Code signature of the new version doesn't match the old version: \(String(describing: requirementString)). Please ensure that old and new app is signed using exactly the same certificate.")
                }
                
                logSigningInfo(for: oldCode!, label: "old info")
                logSigningInfo(for: staticCode!, label: "new info")
            }
        }
        
        return result == noErr
    }
    
    static func codeSignatureIsValid(atBundleURL bundleURL: URL) throws -> Bool {
        var result: OSStatus
        
        var staticCode: SecStaticCode?
        // See in -codeSignatureAtBundleURL:matchesSignatureAtBundleURL:error: for why kSecCSCheckNestedCode is not passed
        result = SecStaticCodeCreateWithPath(bundleURL as CFURL, [], &staticCode)
        guard result == noErr, staticCode != nil else {
            SULog(.error, "Failed to get static code \(result)")
            return false
        }
        
        var cfError: Unmanaged<CFError>?
        let flags = SecCSFlags(rawValue: 0 | kSecCSCheckAllArchitectures)
        result = SecStaticCodeCheckValidityWithErrors(staticCode!, flags, nil, &cfError)
        
        if let tmpError = cfError?.takeUnretainedValue() as? NSError {
            cfError?.release()
            throw tmpError
        }
        
        if result != noErr {
            if result == errSecCSUnsigned {
                SULog(.error, "Error: The app is not signed using Apple Code Signing. \(bundleURL)")
            }
            if result == errSecCSReqFailed {
                logSigningInfo(for: staticCode!, label: "new info")
            }
        }
        
        return result == noErr
    }
    
    static func bundleAtURLIsCodeSigned(_ bundlePath: URL) -> Bool {
        var result: OSStatus
        var staticCode: SecStaticCode?
        
        result = SecStaticCodeCreateWithPath(bundlePath as CFURL, [], &staticCode)
        guard result != errSecCSUnsigned, staticCode != nil else {
            return false
        }
        
        var requirement: SecRequirement?
        // swiftlint:disable:next force_unwrapping
        result = SecCodeCopyDesignatedRequirement(staticCode!, [], &requirement)
        
        guard result != errSecCSUnsigned else {
            return false
        }
        
        return result == 0
    }
    
    private static func codeSignatureInfo(atBundleURL bundlePath: URL) -> [String: Any]? {
        var code: SecStaticCode?
        let result = SecStaticCodeCreateWithPath(bundlePath as CFURL, [], &code)
        if result == noErr, let code = code {
            return codeSignatureInfo(for: code)
        }
        SULog(.error, "Failed to get static code \(result)")
        return nil
    }
    
    private static func codeSignatureInfo(for code: SecStaticCode) -> [String: Any]? {
        var signingInfo: CFDictionary?
        let flags = SecCSFlags(rawValue: kSecCSSigningInformation | kSecCSRequirementInformation | kSecCSDynamicInformation | kSecCSContentInformation)
        
        guard SecCodeCopySigningInformation(code, flags, &signingInfo) == noErr,
              signingInfo != nil
        else { return nil }
        
        // swiftlint:disable:next force_unwrapping
        let signingDict = signingInfo! as NSDictionary
        var relevantInfo: [String: Any] = [:]
        for key in ["format", "identifier", "requirements", "teamid", "signing-time"] {
            relevantInfo[key] = valueOrNil(signingDict.object(forKey: key))
        }
        
        let infoPlist = signingDict["info-plist"] as? [AnyHashable: Any]
        relevantInfo["version"] = valueOrNil(infoPlist?["CFBundleShortVersionString"])
        relevantInfo["build"] = valueOrNil(infoPlist?[kCFBundleVersionKey as String])
        return relevantInfo
    }
    
    private static func logSigningInfo(for code: SecStaticCode, label: String) {
        let relevantInfo = codeSignatureInfo(for: code)
        SULog(.default, "\(label): \(String(describing: relevantInfo))")
    }
    
    private static func valueOrNil<T>(_ value: T?) -> T? {
        return value != nil ? value : nil
    }
}
