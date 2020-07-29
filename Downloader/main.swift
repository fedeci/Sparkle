//
//  main.swift
//  SparkleDownloader
//
//  Created by Federico Ciardi on 26/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

class ServiceDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        // This method is where the NSXPCListener configures, accepts, and resumes a new incoming NSXPCConnection.

        // Configure the connection.
        // First, set the interface that the exported object implements.
        newConnection.exportedInterface = NSXPCInterface(with: SPUDownloaderProtocol.self)

        // Then set remote object interface
        newConnection.remoteObjectInterface = NSXPCInterface(with: SPUDownloaderDelegate.self)

        // Next, set the object that the connection exports. All messages sent on the connection to this service will be sent to the exported object to handle. The connection retains the exported object.
        let exportedObject = SPUDownloader(withDelegate: newConnection.remoteObjectProxy as! SPUDownloaderDelegate)
        newConnection.exportedObject = exportedObject

        // Resuming the connection allows the system to deliver more incoming messages.
        newConnection.resume()

        // Returning true from this method tells the system that you have accepted this connection. If you want to reject the connection for some reason, call invalidate() on the connection and return false.
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
