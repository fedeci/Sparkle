//
//  main.swift
//  Sparkle
//
//  Created by Federico Ciardi on 01/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Cocoa

autoreleasepool {
    let showInstallerProgress = ShowInstallerProgress() as InstallerProgressDelegate

    let appController = InstallerProgressAppController(with: NSApplication.shared, arguments: ProcessInfo.processInfo.arguments, delegate: showInstallerProgress)

    // Ignore SIGTERM because we are going to catch it ourselves
    signal(SIGTERM, SIG_IGN)

    let sigtermSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: DispatchQueue.main)
    sigtermSource.setEventHandler {
        appController.cleanupAndExitWithStatus(Int(SIGTERM))
    }

    sigtermSource.resume()

    appController.run()
}
