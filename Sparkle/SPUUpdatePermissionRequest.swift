//
//  SPUUpdatePermissionRequest.swift
//  Sparkle
//
//  Created by Federico Ciardi on 08/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

private let SPUUpdatePermissionRequestSystemProfileKey = "SPUUpdatePermissionRequestSystemProfile"

/**
 This class represents information needed to make a permission request for checking updates.
*/
@objcMembers
class SPUUpdatePermissionRequest: NSObject {
    
    /**
     A read-only property for the user's system profile.
    */
    private(set) var systemProfile: [[String: String]]
    
    /**
     Initializes a new update permission request instance.
     
     - Parameter systemProfile: The system profile information.
     */
    init(systemProfile: [[String: String]]) {
        self.systemProfile = systemProfile
        super.init()
    }
    
    required init?(coder: NSCoder) {
        guard let systemProfile = coder.decodeObject(of: [NSArray.self, NSDictionary.self, NSString.self], forKey: SPUUpdatePermissionRequestSystemProfileKey) as? [[String: String]] else { return nil }
        self.init(systemProfile: systemProfile)
    }
}

extension SPUUpdatePermissionRequest: NSSecureCoding {
    static var supportsSecureCoding: Bool {
        return true
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(systemProfile, forKey: SPUUpdatePermissionRequestSystemProfileKey)
    }
}
