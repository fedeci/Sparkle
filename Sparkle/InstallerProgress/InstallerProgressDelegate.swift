//
//  InstallerProgressDelegate.swift
//  Installer Progress
//
//  Created by Federico Ciardi on 31/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

@objc
protocol InstallerProgressDelegate: NSObjectProtocol {
    func installerProgressShouldDisplayWithHost(_ host: SUHost)

    func installerProgressShouldStop()
}
