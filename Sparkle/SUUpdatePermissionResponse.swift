//
//  SUUpdatePermissionResponse.swift
//  Sparkle
//
//  Created by Federico Ciardi on 08/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

private let SUUpdatePermissionAutomaticUpdateChecksKey = "SUUpdatePermissionAutomaticUpdateChecks"
private let SUUpdatePermissionSendSystemProfileKey = "SUUpdatePermissionSendSystemProfile"

/// This class represents a response for permission to check updates.
@objcMembers
class SUUpdatePermissionResponse: NSObject {
    
    /// A read-only property indicating whether automatic update checks are allowed or not.
    private(set) var automaticUpdateChecks: Bool
    
    /// A read-only property indicating if system profile should be sent or not.
    private(set) var sendSystemProfile: Bool
    
    /// Initializes a new update permission response instance.
    ///
    /// - Parameter automaticUpdateChecks: Flag for whether to allow automatic update checks.
    /// - Parameter sendSystemProfile: Flag for if system profile information should be sent to the server hosting the appcast.
    init(automaticUpdateChecks: Bool, sendSystemProfile: Bool) {
        self.automaticUpdateChecks = automaticUpdateChecks
        self.sendSystemProfile = sendSystemProfile
        super.init()
    }
    
    required convenience init?(coder: NSCoder) {
        let automaticUpdateChecks = coder.decodeBool(forKey: SUUpdatePermissionAutomaticUpdateChecksKey)
        let sendSystemProfile = coder.decodeBool(forKey: SUUpdatePermissionSendSystemProfileKey)
        self.init(automaticUpdateChecks: automaticUpdateChecks, sendSystemProfile: sendSystemProfile)
    }
}

extension SUUpdatePermissionResponse: NSSecureCoding {
    static var supportsSecureCoding: Bool {
        return true
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(automaticUpdateChecks, forKey: SUUpdatePermissionAutomaticUpdateChecksKey)
        coder.encode(sendSystemProfile, forKey: SUUpdatePermissionSendSystemProfileKey)
    }
}
