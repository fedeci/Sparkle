//
//  SULocalizations.swift
//  Sparkle
//
//  Created by Federico Ciardi on 01/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

func SULocalizedString(_ key: String, _ comment: String = "") -> String {
    let bundle = Bundle(identifier: SPUSparkleBundleIdentifier) ?? Bundle.main
    return NSLocalizedString(key, tableName: "Sparkle", bundle: bundle, comment: comment)
}
