//
//  SPUUpdaterSettings.swift
//  Sparkle
//
//  Created by Federico Ciardi on 09/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

class SPUUpdaterSettings: NSObject {

    private var host: SUHost

    /// Indicates whether or not automatic update checks are enabled.
    var automaticallyChecksForUpdates: Bool {
        // Don't automatically update when the check interval is 0, to be compatible with 1.1 settings.
        guard updateCheckInterval != 0 else { return false }
        return host.boolForKey(SUEnableAutomaticChecksKey)
    }

    /// The regular update check interval.
    var updateCheckInterval: TimeInterval {
        // Find the stored check interval. User defaults override Info.plist.
        let intervalValue = host.objectForKey(SUScheduledCheckIntervalKey) as? NSNumber
        return intervalValue?.doubleValue ?? SUDefaultUpdateCheckInterval
    }

    /// Indicates whether or not automatically downloading updates is allowed to be turned on by the user.
    var allowsAutomaticUpdates: Bool {
        let developerAllowsAutomaticUpdates = host.objectForInfoDictionaryKey(SUAllowsAutomaticUpdatesKey) as? NSNumber
        return developerAllowsAutomaticUpdates?.boolValue ?? true
    }

    /// Indicates whether or not automatically downloading updates is enabled by the user or developer.
    ///
    /// Note this does not indicate whether or not automatic downloading of updates is allowable.
    /// See `allowsAutomaticUpdates` property for that.
    var automaticallyDownloadsUpdates: Bool {
        return host.boolForUserDefaultsKey(SUAutomaticallyUpdateKey)
    }

    /// Indicates whether or not anonymous system profile information is sent when checking for updates.
    var sendsSystemProfile: Bool {
        return host.boolForKey(SUSendProfileInfoKey)
    }

    init(hostBundle: Bundle) {
        host = SUHost(with: hostBundle)
        super.init()
    }
}
