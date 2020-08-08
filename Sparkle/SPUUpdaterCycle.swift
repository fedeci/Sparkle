//
//  SPUUpdaterCycle.swift
//  Sparkle
//
//  Created by Federico Ciardi on 08/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

protocol SPUUpdaterCycleDelegate: NSObjectProtocol {
    
    func resetUpdateCycle()
}

// This notifies the updater for (re-)starting and canceling update cycles
// This class is used so that an updater instance isn't kept alive by a pending update cycle
@objcMembers
class SPUUpdaterCycle: NSObject {
    private weak var delegate: SPUUpdaterCycleDelegate?
    
    init(with delegate: SPUUpdaterCycleDelegate) {
        super.init()
        self.delegate = delegate
    }
    
    func resetUpdateCycleAfterDelay() {
        perform(#selector(resetUpdateCycle), with: nil, afterDelay: 1)
    }
    
    func cancelNextUpdateCycle() {
        SPUUpdaterCycle.cancelPreviousPerformRequests(withTarget: self, selector: #selector(resetUpdateCycle), object: nil)
    }
    
    private func resetUpdateCycle() {
        delegate?.resetUpdateCycle()
    }
}
