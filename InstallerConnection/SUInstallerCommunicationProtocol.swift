//
//  SUInstallerCommunicationProtocol.swift
//  Sparkle
//
//  Created by Federico Ciardi on 04/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

@objc
protocol SUInstallerCommunicationProtocol {
    func handleMessageWithIdentifier(_ identifier: Int32, data: Data)
}
