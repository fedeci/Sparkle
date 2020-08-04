//
//  main.swift
//  SparkleInstallerConnection
//
//  Created by Federico Ciardi on 04/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

class ServiceDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        // This method is where the NSXPCListener configures, accepts, and resumes a new incoming NSXPCConnection.
        
        // Configure the connection.
        // First, set the interface that the exported object implements.
        newConnection.exportedInterface = NSXPCInterface(with: SUInstallerConnectionProtocol.self)
        newConnection.remoteObjectInterface = NSXPCInterface(with: SUInstallerCommunicationProtocol.self)
        
        let exportedObject = SUInstallerConnection(with: newConnection.remoteObjectProxy as! SUInstallerCommunicationProtocol)
        
        newConnection.exportedObject = exportedObject
        
        // Resuming the connection allows the system to deliver more incoming messages.
        newConnection.resume()
        
        return true
    }
}

// Set up the one NSXPCListener for this service. It will handle all incoming connections.
let listener = NSXPCListener.service()

// Create the delegate for the service.
let delegate = ServiceDelegate()
listener.delegate = delegate

// Resuming the serviceListener starts this service. This method does not return.
listener.resume()
