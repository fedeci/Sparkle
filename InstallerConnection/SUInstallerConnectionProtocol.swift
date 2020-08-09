//
//  SUInstallerConnectionProtocol.swift
//  Sparkle
//
//  Created by Federico Ciardi on 04/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

@objc
protocol SUInstallerConnectionProtocol {
    #warning("Inherit SUInstallerCommunicationProtocol?")
    func handleMessageWithIdentifier(_ identifier: Int32, data: Data)

    func setInvalidationHandler(_ invalidationHandler: @escaping () -> Void)

    func setServiceName(_ serviceName: String, hostPath: String, installationType: String)

    func invalidate()
}
