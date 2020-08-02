//
//  SULog.swift
//  Sparkle
//
//  Created by Federico Ciardi on 27/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import asl
import Foundation
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
private var queue: DispatchQueue?
private var logger: OSLog?

private let dispatchOnce: () = {
    let mainBundle = Bundle.main

    if #available(macOS 10.12, *) {
        // This creates a thread-safe object
        logger = OSLog(subsystem: SPUSparkleBundleIdentifier, category: "Sparkle")
    } else {
        var options = UInt32(ASL_OPT_NO_DELAY)
        // Act the same way os_log() does; don't log to stderr if a terminal device is attached
        if isatty(STDERR_FILENO) == 0 {
            options |= UInt32(ASL_OPT_STDERR)
        }

        let displayName = FileManager.default.displayName(atPath: mainBundle.bundlePath)
        displayName.appending(" [Sparkle]").withCString {
            client = asl_open($0, SPUSparkleBundleIdentifier, options)
        }
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

    let logMessage = String(format: format, args)

    // Use os_log if available (on 10.12+)
    if #available(macOS 10.12, *) {
        // We'll make all of our messages formatted as public; just don't log sensitive information.
        // Note we don't take advantage of info like the source line number because we wrap this macro inside our own function
        // And we don't really leverage of os_log's deferred formatting processing because we format the string before passing it in
        guard let logger = logger else { return }
        switch level {
        case .default:
            os_log("%{public}@", log: logger, type: .default, logMessage)
        case .error:
            os_log("%{public}@", log: logger, type: .error, logMessage)
        }

    // Otherwise use ASL
    } else {
        // Return only if both os_log is unavailable and client is nil
        guard let client = client, let queue = queue else { return }
        // Make sure we do not async, because if we async, the log may not be delivered deterministically
        queue.sync {
            guard let message = asl_new(UInt32(ASL_TYPE_MSG)) else { return }

            logMessage.withCString {
                guard asl_set(message, ASL_KEY_MSG, $0) == 0 else { return }
            }

            var levelSetResult: Int?
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
}
