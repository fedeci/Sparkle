//
//  SUBundleIcon.swift
//  Sparkle
//
//  Created by Federico Ciardi on 27/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

@objcMembers
class SUBundleIcon: NSObject {
    // Note: To obtain the most current bundle icon file from the Info dictionary, this should take a SUHost, not a NSBundle
    static func iconURL(for host: SUHost) -> URL? {
        guard let resource = host.objectForInfoDictionaryKey("CFBundleIconFile") as? String else { return nil }

        // The resource could already be containing the path extension, so try again a second time without the extra extension
        let iconURL = host.bundle.url(forResource: resource, withExtension: "icns") ?? host.bundle.url(forResource: resource, withExtension: nil)
        
        return iconURL
    }
}
