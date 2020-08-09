//
//  SUInstallerConnection.swift
//  SparkleInstallerConnection
//
//  Created by Federico Ciardi on 04/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

private let SUInstallerConnectionKeepAliveReason = "Installer Connection Keep Alive"

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@objcMembers
class SUInstallerConnection: NSObject {
    // swiftlint:disable:next weak_delegate
    private var delegate: SUInstallerCommunicationProtocol? // Intentionally not weak for XPC reasons
    private var disabledAutomaticTermination: Bool?
    private var invalidationBlock: (() -> Void)?
    private var connection: NSXPCConnection?

    init(with delegate: SUInstallerCommunicationProtocol) {
        self.delegate = delegate

        // If we are a XPC service, protect it from being terminated until the invalidation handler is set
        disabledAutomaticTermination = true
        ProcessInfo.processInfo.disableAutomaticTermination(SUInstallerConnectionKeepAliveReason)
    }

    private func enableAutomaticTermination() {
        if disabledAutomaticTermination == true {
            ProcessInfo.processInfo.enableAutomaticTermination(SUInstallerConnectionKeepAliveReason)
            disabledAutomaticTermination = false
        }
    }
}

extension SUInstallerConnection: SUInstallerConnectionProtocol {
    func handleMessageWithIdentifier(_ identifier: Int32, data: Data) {
        (connection?.remoteObjectProxy as? SUInstallerCommunicationProtocol)?.handleMessageWithIdentifier(identifier, data: data)
    }

    func setInvalidationHandler(_ invalidationHandler: @escaping () -> Void) {
        invalidationBlock = invalidationHandler
        // No longer needed because of invalidation callback
        enableAutomaticTermination()
    }

    func setServiceName(_ serviceName: String, hostPath: String, installationType: String) {
        let options = SPUNeedsSystemAuthorizationAccess(path: hostPath, installationType: installationType) ? NSXPCConnection.Options.privileged : NSXPCConnection.Options()
        let connection = NSXPCConnection(machServiceName: serviceName, options: options)

        connection.exportedInterface = NSXPCInterface(with: SUInstallerCommunicationProtocol.self)
        connection.exportedObject = delegate

        connection.remoteObjectInterface = NSXPCInterface(with: SUInstallerCommunicationProtocol.self)

        self.connection = connection

        self.connection?.interruptionHandler = { [weak self] in
            self?.connection?.invalidate()
        }

        self.connection?.invalidationHandler = { [weak self] in
            self?.connection = nil
            self?.invalidate()
        }

        self.connection?.resume()
    }

    func invalidate() {
        DispatchQueue.main.async {
            self.connection?.invalidate()
            self.connection = nil

            self.invalidationBlock?()
            self.invalidationBlock = nil
            // Break the retain cycle
            self.delegate = nil

            self.enableAutomaticTermination()
        }
    }
}
