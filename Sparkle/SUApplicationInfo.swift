//
//  SUApplicationInfo.swift
//  Sparkle
//
//  Created by Federico Ciardi on 01/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Cocoa

@objcMembers
class SUApplicationInfo: NSObject {
    static func isBackgroundApplication(_ application: NSApplication) -> Bool {
        return application.activationPolicy() == .accessory
    }

    static func bestIcon(for host: SUHost) -> NSImage {
        let iconURL = SUBundleIcon.iconURL(for: host)

        if let iconURL = iconURL, let icon = NSImage(contentsOf: iconURL) {
            return icon
        }
        // Use a default icon if none is defined.

        // this asumption may not be correct (eg. even though we're not the main bundle, it could be still be a regular app)
        // but still better than nothing if no icon was included
        let isMainBundle = host.bundle == Bundle.main
        let fileType = isMainBundle ? kUTTypeApplication : kUTTypeBundle
        return NSWorkspace.shared.icon(forFile: fileType as String)
    }
}
