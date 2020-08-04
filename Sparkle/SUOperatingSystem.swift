//
//  SUOperatingSystem.swift
//  Sparkle
//
//  Created by Federico Ciardi on 28/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

@objcMembers
class SUOperatingSystem: NSObject {
    /// May return { 0, 0, 0 } if error occurred
    static func operatingSystemVersion() -> OperatingSystemVersion {
        guard #available(macOS 10.10, *) else {
            var version = OperatingSystemVersion(majorVersion: 0, minorVersion: 0, patchVersion: 0)
            if !ProcessInfo.instancesRespond(to: #selector(operatingSystemVersion)) {
                let coreServices = try? FileManager.default.url(for: .coreServiceDirectory, in: .systemDomainMask, appropriateFor: nil, create: false)

                if let url = coreServices?.appendingPathComponent("SystemVersion.plist"),
                   let dictionary = NSDictionary(contentsOf: url),
                   let components = (dictionary["ProductVersion"] as? String)?.components(separatedBy: ".") {

                    version.majorVersion = components.count > 0 ? Int(components[0]) ?? 0 : 0
                    version.majorVersion = components.count > 1 ? Int(components[1]) ?? 0 : 0
                    version.majorVersion = components.count > 2 ? Int(components[2]) ?? 0 : 0
                }
            }
            return version
        }
        // Default return for macos 10.10+
        return ProcessInfo.processInfo.operatingSystemVersion
    }

    @available(*, deprecated, message: "Use Swift's native availability checking")
    static func isOperatingSystemAtLeastVersion(_ version: OperatingSystemVersion) -> Bool {
        let systemVersion = operatingSystemVersion()
        if systemVersion.majorVersion == version.majorVersion {
            if systemVersion.minorVersion == version.minorVersion {
                return systemVersion.patchVersion >= version.patchVersion
            }
            return systemVersion.minorVersion >= version.minorVersion
        }
        return systemVersion.majorVersion >= version.majorVersion
    }

    static func systemVersionString() -> String {
        let version = operatingSystemVersion()
        #warning("Check string formatting, may return nil?")
        return String(format: "%ld.%ld.%ld", version.majorVersion, version.minorVersion, version.patchVersion)
    }
}
