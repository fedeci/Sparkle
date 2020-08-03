//
//  SPUInstallationType.swift
//  Sparkle
//
//  Created by Federico Ciardi on 26/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

let SPUInstallationTypeApplication = "application" // the default installation type for ordinary application updates
let SPUInstallationTypeGuidedPackage = "package" // the preferred installation type for package installations
let SPUInstallationTypeInteractivePackage = "interactive-package" // the deprecated installation type; use guided package instead

let SPUInstallationTypeDefault = SPUInstallationTypeApplication

let SPUInstallationTypesArray = [
    SPUInstallationTypeApplication,
    SPUInstallationTypeGuidedPackage,
    SPUInstallationTypeInteractivePackage
]

func SPUValidInstallationType(_ item: String?) -> Bool {
    guard let item = item else { return false }
    return SPUInstallationTypesArray.contains(item)
}
