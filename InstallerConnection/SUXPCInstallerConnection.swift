//
//  SUXPCInstallerConnection.swift
//  Sparkle
//
//  Created by Federico Ciardi on 04/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

@objcMembers
class SUXPCInstallerConnection: NSObject {
    // swiftlint:disable:next weak_delegate
    private var delegate: SUInstallerCommunicationProtocol?
    private var connection: NSXPCConnection?
    private var invalidationBlock: (() -> Void)?

    init(with delegate: SUInstallerCommunicationProtocol) {
        super.init()
        connection = NSXPCConnection(serviceName: SPUInstallerConnectionBundleIdentifier)
        connection?.remoteObjectInterface = NSXPCInterface(with: SUInstallerConnectionProtocol.self)

        connection?.invalidationHandler = { [weak self] in
            self?.invokeInvalidation()
        }

        connection?.interruptionHandler = { [weak self] in
            self?.invokeInvalidation()
            self?.connection?.invalidate()
        }

        self.delegate = delegate

        connection?.exportedInterface = NSXPCInterface(with: SUInstallerConnectionProtocol.self)
        connection?.exportedObject = delegate

        connection?.resume()
    }

    private func invokeInvalidation() {
        invalidationBlock?()
        invalidationBlock = nil
        // Break our retain cycle
        delegate = nil
    }
}

extension SUXPCInstallerConnection: SUInstallerConnectionProtocol {
    func handleMessageWithIdentifier(_ identifier: Int32, data: Data) {
        (connection?.remoteObjectProxy as? SUInstallerConnectionProtocol)?.handleMessageWithIdentifier(identifier, data: data)
    }

    func setInvalidationHandler(_ invalidationHandler: @escaping () -> Void) {
        invalidationBlock = invalidationHandler

        (connection?.remoteObjectProxy as? SUInstallerConnectionProtocol)?.setInvalidationHandler { [weak self] in
            self?.invokeInvalidation()
        }
    }

    func setServiceName(_ serviceName: String, hostPath: String, installationType: String) {
        (connection?.remoteObjectProxy as? SUInstallerConnectionProtocol)?.setServiceName(serviceName, hostPath: hostPath, installationType: installationType)
    }

    func invalidate() {
        (connection?.remoteObjectProxy as? SUInstallerConnectionProtocol)?.invalidate()
        connection?.invalidate()
        connection = nil
    }
}
