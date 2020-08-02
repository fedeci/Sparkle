//
//  SUStatusInfoProtocol.swift
//  Installer Progress
//
//  Created by Federico Ciardi on 01/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

@objc
protocol SUStatusInfoProtocol {
    func probeStatusInfoWithReply(_ reply: @escaping (Data?) -> Void)

    func probeStatusConnectivityWithReply(_ reply: () -> Void)
}
