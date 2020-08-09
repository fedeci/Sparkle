//
//  AgentConnection.swift
//  Sparkle
//
//  Created by Federico Ciardi on 09/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

protocol AgentConnectionDelegate: NSObjectProtocol {
    
    func agentConnectionDidInitiate()
    
    func agentConnectionDidInvalidate()
}

class AgentConnection: NSObject {
    private weak var delegate: AgentConnectionDelegate?
    private var xpcListener: NSXPCListener?
    private var activeConnection: NSXPCConnection?
    private(set) var agent: SPUInstallerAgentProtocol?
    private(set) var connected: Bool
    
    init(hostBundleIdentifier bundleIdentifier: String, delegate: AgentConnectionDelegate) {
        super.init()
        // Agents should always be the one that connect to daemons due to how mach bootstraps work
        // For this reason, we are the ones that are creating a listener, not the agent
        xpcListener = NSXPCListener(machServiceName: SPUProgressAgentServiceName(for: bundleIdentifier))
        xpcListener?.delegate = self
        self.delegate = delegate
    }
    
    func startListener() {
        xpcListener?.resume()
    }
    
    func invalidate() {
        delegate = nil
        
        activeConnection?.invalidate()
        activeConnection = nil
        
        xpcListener?.invalidate()
        xpcListener = nil
    }
}

extension AgentConnection: NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        
        guard activeConnection == nil else {
            newConnection.invalidate()
            return false
        }
        
        newConnection.exportedInterface = NSXPCInterface(with: SUInstallerAgentInitiationProtocol.self)
        newConnection.exportedObject = self
        
        newConnection.remoteObjectInterface = NSXPCInterface(with: SPUInstallerAgentProtocol.self)
        
        activeConnection = newConnection
        
        newConnection.interruptionHandler = { [weak self] in
            self?.activeConnection?.invalidate()
        }
        
        newConnection.invalidationHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.delegate?.agentConnectionDidInvalidate()
            }
        }
        
        newConnection.resume()
        
        agent = newConnection.remoteObjectProxy as? SPUInstallerAgentProtocol
        return true
    }
}

extension AgentConnection: SUInstallerAgentInitiationProtocol {
    func connectionDidInitiateWithReply(_ acknowledgement: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.connected = true
            
            self.delegate?.agentConnectionDidInitiate()
            self.delegate = nil
        }
        
        acknowledgement()
    }
}
