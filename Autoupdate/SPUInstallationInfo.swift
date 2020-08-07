//
//  SPUInstallationInfo.swift
//  Sparkle
//
//  Created by Federico Ciardi on 07/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

private let SUAppcastItemKey = "SUAppcastItem"
private let SUCanSilentlyInstallKey = "SUCanSilentlyInstall"

class SPUInstallationInfo: NSObject {
    private(set) var appcastItem: SUAppcastItem
    private(set) var canSilentlyInstall: Bool
    
    init(with appcastItem: SUAppcastItem, canSilentlyInstall: Bool) {
        self.appcastItem = appcastItem
        self.canSilentlyInstall = canSilentlyInstall
        super.init()
    }
    
    required convenience init?(coder: NSCoder) {
        guard let appcastItem = coder.decodeObject(forKey: SUAppcastItemKey) as? SUAppcastItem else { return nil }
        
        let canSilentlyInstall = coder.decodeBool(forKey: SUCanSilentlyInstallKey)
        self.init(with: appcastItem, canSilentlyInstall: canSilentlyInstall)
    }
}

extension SPUInstallationInfo: NSSecureCoding {
    static var supportsSecureCoding: Bool {
        return true
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(appcastItem, forKey: SUAppcastItemKey)
        coder.encode(canSilentlyInstall, forKey: SUCanSilentlyInstallKey)
    }
}
