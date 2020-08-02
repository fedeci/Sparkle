//
//  SPUInstallerAgentProtocol.swift
//  Installer Progress
//
//  Created by Federico Ciardi on 31/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

@objc
protocol SPUInstallerAgentProtocol {
    func registerApplicationBundlePath(_ applicationBundlePath: String, reply: @escaping (NSNumber?) -> Void)

    func registerInstallationInfoData(_ installationInfoData: Data)

    func sendTerminationSignal()

    func showProgress()

    func stopProgress()

    func relaunchPath(_ requestedPathToRelaunch: String)
}
