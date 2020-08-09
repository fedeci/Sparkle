//
//  SUXPCInstallerStatus.swift
//  Sparkle
//
//  Created by Federico Ciardi on 07/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

class SUXPCInstallerStatus: NSObject {
    private var connection: NSXPCConnection?
    private var invalidationBlock: (() -> Void)?

    override init() {
        super.init()

        connection = NSXPCConnection(serviceName: SPUInstallerStatusBundleIdentifier)
        connection?.remoteObjectInterface = NSXPCInterface(with: SUInstallerStatusProtocol.self)

        connection?.invalidationHandler = { [weak self] in
            self?.invokeInvalidation()
        }

        connection?.interruptionHandler = { [weak self] in
            self?.invokeInvalidation()
            self?.connection?.invalidate()
        }

        connection?.resume()
    }

    private func invokeInvalidation() {
        invalidationBlock?()
        invalidationBlock = nil
    }
}

extension SUXPCInstallerStatus: SUInstallerStatusProtocol {
    func probeStatusInfoWithReply(_ reply: @escaping (Data?) -> Void) {
        (connection?.remoteObjectProxy as? SUInstallerStatusProtocol)?.probeStatusInfoWithReply(reply)
    }

    func probeStatusConnectivityWithReply(_ reply: () -> Void) {
        (connection?.remoteObjectProxy as? SUInstallerStatusProtocol)?.probeStatusConnectivityWithReply(reply)
    }

    func setInvalidationHandler(_ invalidationHandler: @escaping () -> Void) {
        invalidationBlock = invalidationHandler

        (connection?.remoteObjectProxy as? SUInstallerStatusProtocol)?.setInvalidationHandler { [weak self] in
            self?.invokeInvalidation()
        }
    }

    func setServiceName(_ serviceName: String) {
        (connection?.remoteObjectProxy as? SUInstallerStatusProtocol)?.setServiceName(serviceName)
    }

    func invalidate() {
        (connection?.remoteObjectProxy as? SUInstallerStatusProtocol)?.invalidate()
        connection?.invalidate()
        connection = nil
    }
}
