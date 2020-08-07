//
//  SUInstallerStatus.swift
//  SparkleInstallerStatus
//
//  Created by Federico Ciardi on 07/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@objcMembers
class SUInstallerStatus: NSObject {
    private var connection: NSXPCConnection?
    private var invalidationBlock: (() -> Void)?
}

extension SUInstallerStatus: SUInstallerStatusProtocol {
    func probeStatusInfoWithReply(_ reply: @escaping (Data?) -> Void) {
        (connection?.remoteObjectProxy as? SUStatusInfoProtocol)?.probeStatusInfoWithReply(reply)
    }
    
    func probeStatusConnectivityWithReply(_ reply: () -> Void) {
        (connection?.remoteObjectProxy as? SUStatusInfoProtocol)?.probeStatusConnectivityWithReply(reply)
    }
    
    func setInvalidationHandler(_ invalidationHandler: @escaping () -> Void) {
        invalidationBlock = invalidationHandler
    }
    
    func setServiceName(_ serviceName: String) {
        let connection = NSXPCConnection(machServiceName: serviceName, options: NSXPCConnection.Options(rawValue: 0))
        
        connection.remoteObjectInterface = NSXPCInterface(with: SUStatusInfoProtocol.self)
        
        self.connection = connection
        
        connection.interruptionHandler = { [weak self] in
            self?.connection?.invalidate()
        }
        
        connection.invalidationHandler = { [weak self] in
            guard let self = self else { return }
            self.connection = nil
            self.invalidate()
        }
        
        connection.resume()
    }
    // This method can be called by us or from a remote
    func invalidate() {
        DispatchQueue.main.async {
            self.connection?.invalidate()
            self.connection = nil
            
            self.invalidationBlock?()
            self.invalidationBlock = nil
        }
    }
}
