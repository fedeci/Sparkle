//
//  SPUXPCServiceInfo.swift
//  Sparkle
//
//  Created by Federico Ciardi on 07/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

func SPUXPCServiceExists(bundleName: String) -> Bool {
    guard let xpcBundle = SPUXPCServiceBundle(bundleName: bundleName) else { return false }
    
    let version = xpcBundle.object(forInfoDictionaryKey: kCFBundleVersionKey as String)
    let projectVersion = CURRENT_PROJECT_VERSION
    
    guard version != nil && version == projectVersion else {
        NSLog("Error: XPC Version mismatch. Framework version is \(projectVersion) but XPC Service (\(xpcBundle.bundlePath)) version is \(version)")
        NSLog("Not using XPC Service...")
        return false
    }
    
    return true
}

func SPUXPCServiceBundle(bundleName: String) -> Bundle? {
    let mainBundle = Bundle.main
    guard let executableURL = mainBundle.executableURL else { return nil }
    
    let xpcBundleURL = executableURL.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("XPCServices").appendingPathComponent(bundleName).appendingPathExtension("xpc")
    
    return Bundle(url: xpcBundleURL)
}
