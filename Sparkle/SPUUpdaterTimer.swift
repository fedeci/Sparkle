//
//  SPUUpdaterTimer.swift
//  Sparkle
//
//  Created by Federico Ciardi on 08/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

protocol SPUUpdaterTimerDelegate: NSObjectProtocol {
    
    func updaterTimerDidFire()
}

// This notifies the updater for scheduled update checks
// This class is used so that an updater instance isn't kept alive by a scheduled update check
@objcMembers
class SPUUpdaterTimer: NSObject {
    private weak var delegate: SPUUpdaterTimerDelegate?
    private var timer: Timer?
    
    init(with delegate: SPUUpdaterTimerDelegate) {
        super.init()
        self.delegate = delegate
    }
    
    func startAndFire(after delay: TimeInterval) {
        assert(timer == nil)
        timer = Timer(timeInterval: delay, target: self, selector: #selector(fire), userInfo: nil, repeats: false)
    }
    
    func invalidate() {
        timer?.invalidate()
        timer = nil
    }
    
    private func fire(_ timer: Timer) {
        delegate?.updaterTimerDidFire()
        timer = nil
    }
}
