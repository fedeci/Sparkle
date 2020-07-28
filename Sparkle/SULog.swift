//
//  SULog.swift
//  Sparkle
//
//  Created by Federico Ciardi on 27/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation
import asl
import os.log


enum SULogLevel: UInt8 {
    // This level is for information that *might* result a failure
    // For now until other levels are added, this may serve as a level for other information as well
    case `default`
    // This level is for errors that occurred
    case error
}

// MARK: - One-time initialized variables
private var client: aslclient?
private var hasOSLogging: Bool?
private var queue: DispatchQueue?
private var logger: OSLog?

private let dispatchOnce: () = {
    let mainBundle = Bundle.main
    
    hasOSLogging = SUOperatingSystem.isOperatingSystemAtLeastVersion(OperatingSystemVersion(majorVersion: 10, minorVersion: 12, patchVersion: 0))
    
    if hasOSLogging == true {
        if #available(OSX 10.12, *) {
            // This creates a thread-safe object
            logger = OSLog(subsystem: SUBundleIdentifier, category: "Sparkle")
        }
    } else {
        var options: UInt32 = UInt32(ASL_OPT_NO_DELAY)
        // Act the same way os_log() does; don't log to stderr if a terminal device is attached
        if isatty(STDERR_FILENO) == 0 {
            options |= UInt32(ASL_OPT_STDERR)
        }
        
        let displayName = FileManager.default.displayName(atPath: mainBundle.bundlePath)
        displayName.appending(" [Sparkle]").withCString {
            client = asl_open($0, SUBundleIdentifier, options)
        }
        queue = DispatchQueue(label: "")
    }
    queue = DispatchQueue(label: "")
}()


// Logging utlity function that is thread-safe
// On 10.12 or later this uses os_log
// Otherwise on older systems this uses ASL
// For debugging command line tools, you may have to use Console.app or log(1) to view log messages
// Try to keep log messages as compact/short as possible
func SULog(_ level: SULogLevel, _ format: String, _ args: CVarArg...) {
    // dispatch once
    _ = dispatchOnce
    
    // Return only if both hasOSLogging is false and client is nil
    guard hasOSLogging != nil, !(!hasOSLogging! && client == nil) else { return }
    
    let logMessage = String(format: format, locale: nil, args)
    
    // Use os_log if available (on 10.12+)
    if hasOSLogging! {
        // We'll make all of our messages formatted as public; just don't log sensitive information.
        // Note we don't take advantage of info like the source line number because we wrap this macro inside our own function
        // And we don't really leverage of os_log's deferred formatting processing because we format the string before passing it in
        guard let logger = logger else { return }
        if #available(macOS 10.12, *) {
            switch level {
            case .default:
                os_log("%{public}@", log: logger, type: .default, logMessage)
            case .error:
                os_log("%{public}@", log: logger, type: .error, logMessage)
            }
        }
        return
    }
    
    // Otherwise use ASL
    // Make sure we do not async, because if we async, the log may not be delivered deterministically
    guard queue != nil else { return }
    queue!.sync {
        guard let message = asl_new(UInt32(ASL_TYPE_MSG)) else { return }
        
        logMessage.withCString {
            guard (asl_set(message, ASL_KEY_MSG, $0) == 0) else { return }
        }
        
        var levelSetResult: Int? = nil
        switch level {
        case .default:
            levelSetResult = Int(asl_set(message, ASL_KEY_LEVEL, "\(ASL_LEVEL_WARNING)"))
        case .error:
            levelSetResult = Int(asl_set(message, ASL_KEY_LEVEL, "\(ASL_LEVEL_ERR)"))
        }
        
        guard levelSetResult == 0 else { return }
        
        asl_send(client, message)
    }
}
