//
//  SUInstallerStatusProtocol.swift
//  SparkleInstallerStatus
//
//  Created by Federico Ciardi on 07/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

// The protocol that this service will vend as its API. This header file will also need to be visible to the process hosting the service.
@objc
protocol SUInstallerStatusProtocol {
    // Even though this is declared in SUStatusInfoProtocol, we should declare it here because macOS 10.8 doesn't traverse adopted protocols,
    // which is why this protocol doesn't adopt SUStatusInfoProtocol
    func probeStatusInfoWithReply(_ reply: @escaping (Data?) -> Void)
    // Even though this is declared in SUStatusInfoProtocol, we should declare it here because macOS 10.8 doesn't traverse adopted protocols,
    // which is why this protocol doesn't adopt SUStatusInfoProtocol
    func probeStatusConnectivityWithReply(_ reply: () -> Void)

    func setInvalidationHandler(_ invalidationHandler: @escaping () -> Void)

    func setServiceName(_ serviceName: String)

    func invalidate()
}
