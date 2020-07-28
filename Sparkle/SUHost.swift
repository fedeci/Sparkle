//
//  SUHost.swift
//  Sparkle
//
//  Created by Federico Ciardi on 27/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation
import Darwin

@objcMembers
class SUHost: NSObject {
    private(set) var bundle: Bundle!
    private var defaultsDomain: String?
    private var usesStandardUserDefaults: Bool!
    
    override var description: String {
        return "\(type(of: self)) <\(bundlePath)>"
    }
    
    private var isMainBundle: Bool {
        bundle.isEqual(to: Bundle.main)
    }
    
    var bundlePath: String {
        return bundle.bundlePath
    }
    
    var name: String {
        // Allow host bundle to provide a custom name
        if let name = objectForInfoDictionaryKey("SUBundleName") as? String, name.count > 0 {
            return name
        }
        
        if let name = objectForInfoDictionaryKey("CFBundleDisplayName") as? String, name.count > 0 {
            return name
        }
        
        if let name = objectForInfoDictionaryKey(kCFBundleNameKey as String) as? String, name.count > 0 {
            return name
        }
        
        return URL(fileURLWithPath: FileManager.default.displayName(atPath: bundlePath)).deletingPathExtension().absoluteString
    }
    
    var validVersion: Bool {
        return isValidVersion(_version)
    }
    
    private var _version: String? {
        let version = objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String
        return isValidVersion(version) ? version : nil
    }
    
    var version: String {
        if let version = _version {
            return version
        }
        SULog(.error, "This host (\(bundlePath) has no \(String(describing: kCFBundleVersionKey))! This attribute is required.")
        // Instead of abort()-ing, return an empty string to satisfy the non-nil contract.
        return ""
    }
    
    var displayVersion: String {
        if let shortVersionString = objectForInfoDictionaryKey("CFBundleShortVersionString") as? String {
            return shortVersionString
        }
        return version // Fall back on the normal version string.
    }
    
    var isRunningOnReadOnlyVolume: Bool {
        #warning("Should work")
        // create a blank instance of statfs
        let stafs_info_ptr = UnsafeMutablePointer<statfs>.allocate(capacity: MemoryLayout<statfs>.size)
        var statfs_info = stafs_info_ptr.move()
        
        statfs(bundle.bundlePath, &statfs_info)
        return (statfs_info.f_flags & UInt32(MNT_RDONLY)) != 0
    }
    
    var isRunningTranslocated: Bool {
        let path = bundle.bundlePath
        return path.range(of: "/AppTranslocation/") != nil
    }
    
    private var publicEDKey: String? {
        return objectForInfoDictionaryKey(SUPublicEDKeyKey) as? String
    }
    
    private var publicDSAKey: String? {
        // Maybe the key is just a string in the Info.plist.
        if let key = objectForInfoDictionaryKey(SUPublicDSAKeyKey) as? String {
            return key
        }
        
        // More likely, we've got a reference to a Resources file by filename:
        guard let keyFilename = publicDSAKeyFileKey else { return nil }
        
        guard let keyPath = bundle.path(forResource: keyFilename, ofType: nil) else { return nil }
        
        do {
            let key = try String(contentsOfFile: keyPath, encoding: .ascii)
            return key
        } catch let error {
            SULog(.error, "Error loading \(keyPath): \(error)")
        }
        return nil
    }
    
    var publicKeys: SUPublicKeys? {
        return SUPublicKeys(withDsa: publicDSAKey, ed: publicEDKey)
    }
    
    var publicDSAKeyFileKey: String? {
        return objectForInfoDictionaryKey(SUPublicDSAKeyFileKey) as? String
    }
    
    init(with bundle: Bundle) {
        super.init()
        
        self.bundle = bundle
        if bundle.bundleIdentifier == nil {
            SULog(.error, "Error: the bundle being updated at \(bundle) has no \(String(describing: kCFBundleIdentifierKey))! This will cause preference read/write to not work properly.")
        }
        
        defaultsDomain = objectForInfoDictionaryKey(SUDefaultsDomainKey) as? String
        if defaultsDomain == nil {
            defaultsDomain = bundle.bundleIdentifier
        }
        
        let mainBundleIdentifier = Bundle.main.bundleIdentifier
        usesStandardUserDefaults = defaultsDomain == nil || defaultsDomain == mainBundleIdentifier
    }
    
    private func isValidVersion(_ version: String?) -> Bool {
        return version != nil && version?.count != 0
    }
    
    func objectForInfoDictionaryKey(_ key: String) -> Any? {
        if isMainBundle {
            // Common fast path - if we're updating the main bundle, that means our updater and host bundle's lifetime is the same
            // If the bundle happens to be updated or change, that means our updater process needs to be terminated first to do it safely
            // Thus we can rely on the cached Info dictionary
            return bundle.object(forInfoDictionaryKey: key)
        } else {
            // Slow path - if we're updating another bundle, we should read in the most up to date Info dictionary because
            // the bundle can be replaced externally or even by us.
            // This is the easiest way to read the Info dictionary values *correctly* despite some performance loss.
            // A mutable method to reload the Info dictionary at certain points and have it cached at other points is challenging to do correctly.
            if let cfInfoDictionary = CFBundleCopyInfoDictionaryInDirectory(bundle.bundleURL as CFURL) {
                let infoDictionary = cfInfoDictionary as NSDictionary
                return infoDictionary.object(forKey: key)
            }
            return nil
        }
    }
    
    func boolForInfoDictionaryKey(_ key: String) -> Bool? {
        return (objectForKey(key) as? NSNumber)?.boolValue
    }
    
    func objectForUserDefaultsKey(_ defaultName: String) -> Any? {
        guard defaultsDomain != nil else { return nil }
        
        guard !usesStandardUserDefaults else { return UserDefaults.standard.object(forKey: defaultName) }
        
        guard let defaultsDomain = defaultsDomain else { return nil }
        let obj = CFPreferencesCopyAppValue(defaultName as CFString, defaultsDomain as CFString)
        return obj
    }
    
    func setObject(_ value: Any, forUserDefaultsKey defaultName: String) {
        if usesStandardUserDefaults {
            UserDefaults.standard.setValue(value, forKey: defaultName)
        } else {
            guard let defaultsDomain = defaultsDomain else { return }
            CFPreferencesSetValue(defaultName as CFString, value as CFPropertyList, defaultsDomain as CFString, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
            CFPreferencesSynchronize(defaultsDomain as CFString, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        }
    }
    
    func boolForUserDefaultsKey(_ defaultName: String) -> Bool {
        if usesStandardUserDefaults {
            return UserDefaults.standard.bool(forKey: defaultName)
        } else {
            guard let defaultsDomain = defaultsDomain, let plr = CFPreferencesCopyAppValue(defaultName as CFString, defaultsDomain as CFString), CFGetTypeID(plr) == CFBooleanGetTypeID() else {
                return false
            }
            
            return CFBooleanGetValue((plr as! CFBoolean))
        }
    }
    
    func setBool(_ value: Bool, forUserDefaultsKey defaultName: String) {
        if usesStandardUserDefaults {
            UserDefaults.standard.set(value, forKey: defaultName)
        } else {
            guard let defaultsDomain = defaultsDomain else { return }
            CFPreferencesSetValue(defaultName as CFString, value as CFBoolean, defaultsDomain as CFString, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
            CFPreferencesSynchronize(defaultsDomain as CFString, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        }
    }
    
    func objectForKey(_ key: String) -> Any? {
        if let object = objectForUserDefaultsKey(key) {
            return object
        } else {
            return objectForInfoDictionaryKey(key)
        }
    }
    
    func boolForKey(_ key: String) -> Bool? {
        if let _ = objectForUserDefaultsKey(key) {
            return boolForUserDefaultsKey(key)
        } else {
            return boolForInfoDictionaryKey(key)
        }
    }
}
