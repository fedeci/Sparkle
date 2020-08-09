//
//  SUVersionComparisonProtocol.swift
//  Sparkle
//
//  Created by Federico Ciardi on 03/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

/// Provides version comparison facilities for Sparkle.
@objc
protocol SUVersionComparison {
    
    /// An abstract method to compare two version strings.
    ///
    /// Should return OrderedAscending if b `>` a, NSOrderedDescending if b `<` a, and OrderedSame if they are equivalent.
    func compareVersion(_ versionA: String, toVersion versionB: String) -> ComparisonResult // *** MAY BE CALLED ON NON-MAIN THREAD!
}
