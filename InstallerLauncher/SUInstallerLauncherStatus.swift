//
//  SUInstallerLauncherStatus.swift
//  Sparkle
//
//  Created by Federico Ciardi on 07/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

enum SUInstallerLauncherStatus: Int {
    case success = 0
    case canceled = 1
    case authorizeLater = 3
    case failure = 4
}
