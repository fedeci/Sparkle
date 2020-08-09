//
//  ShowInstallerProgress.swift
//  Installer Progress
//
//  Created by Federico Ciardi on 01/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

class ShowInstallerProgress: NSObject {
    private var statusController: SUStatusController?
}

extension ShowInstallerProgress: InstallerProgressDelegate {
    func installerProgressShouldDisplayWithHost(_ host: SUHost) {
        statusController = SUStatusController(with: host)
        statusController?.setButtonTitle(SULocalizedString("Cancel Update"), target: nil, action: nil, isDefault: false)
        statusController?.beginAction(with: SULocalizedString("Installing update..."), maxProgressValue: 0, statusText: "")
        statusController?.showWindow(self)
    }

    func installerProgressShouldStop() {
        statusController?.close()
        statusController = nil
    }
}
