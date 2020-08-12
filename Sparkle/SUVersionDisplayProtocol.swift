//
//  SUVersionDisplayProtocol.swift
//  Sparkle
//
//  Created by Federico Ciardi on 11/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

/// Applies special display formatting to version numbers.
protocol SUVersionDisplay {
    
    /// Formats two version strings.
    ///
    /// Both versions are provided so that important distinguishing information can be displayed while also leaving out unnecessary/confusing parts.
    func formatVersion(_ inOutVersionA: inout String, andVersion inOutVersionB: inout String)
}
