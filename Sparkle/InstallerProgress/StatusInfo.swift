//
//  StatusInfo.swift
//  Installer Progress
//
//  Created by Federico Ciardi on 01/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

@objcMembers
class StatusInfo: NSObject {
    var installationInfoData: Data?
    private var xpcListener: NSXPCListener?
    
    init(hostBundleIdentifier: String) {
        super.init()
        xpcListener = NSXPCListener(machServiceName: SPUStatusInfoServiceName(for: hostBundleIdentifier))
        xpcListener?.delegate = self
    }
    
    func startListener() {
        xpcListener?.resume()
    }
    
    func invalidate() {
        xpcListener?.invalidate()
        xpcListener = nil
    }
}

extension StatusInfo: NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: SUStatusInfoProtocol.self)
        newConnection.exportedObject = self
        
        newConnection.resume()
        
        return true
    }
}

extension StatusInfo: SUStatusInfoProtocol {
    func probeStatusInfoWithReply(_ reply: @escaping (Data?) -> Void) {
        DispatchQueue.main.async {
            reply(self.installationInfoData)
        }
    }
    
    func probeStatusConnectivityWithReply(_ reply: () -> Void) {
        reply()
    }
}
