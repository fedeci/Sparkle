//
//  SUInstallerLauncherProtocol.swift
//  Sparkle
//
//  Created by Federico Ciardi on 07/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

protocol SUInstallerLauncherProtocol {
    func launchInstallerWithHostBundlePath(_ hostBundlePath: String, authorizationPrompt: String, installationType: String, allowingDriverInteraction: Bool, allowingUpdaterInteraction: Bool, completion: (SUInstallerLauncherStatus) -> Void)
    
    func checkIfApplicationInstallationRequiresAuthorizationWithHostBundlePath(_ hostBundlePath: String, reply: (Bool) -> Void)
}
