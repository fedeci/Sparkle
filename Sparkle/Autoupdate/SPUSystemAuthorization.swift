//
//  SPUSystemAuthorization.swift
//  Sparkle
//
//  Created by Federico Ciardi on 04/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

func SPUNeedsSystemAuthorizationAccess(path: String, installationType: String) -> Bool {
    let needsAuthorization: Bool
    if installationType == SPUInstallationTypeGuidedPackage {
        needsAuthorization = true
    } else if installationType == SPUInstallationTypeInteractivePackage {
        needsAuthorization = false
    } else {
        let fileManager = FileManager.default
        let hasWritability = fileManager.isWritableFile(atPath: path) && fileManager.isWritableFile(atPath: URL(fileURLWithPath: path).deletingLastPathComponent().absoluteString)
        if !hasWritability {
            needsAuthorization = true
        } else {
            // Just because we have writability access does not mean we can set the correct owner/group
            // Test if we can set the owner/group on a temporarily created file
            // If we can, then we can probably perform an update without authorization
            let tempFilename = "permission_test"
            let suFileManager = SUFileManager()
            
            if let tempDirectoryURL = try? suFileManager.makeTemporaryDirectory(with: tempFilename, appropriateFor: URL(fileURLWithPath: NSTemporaryDirectory())) {
                let tempFileURL: URL = tempDirectoryURL.appendingPathComponent(tempFilename)
                if (try? Data().write(to: tempFileURL)) == nil {
                    // Obvious indicator we may need authorization
                    needsAuthorization = true
                } else {
                    needsAuthorization = (try? suFileManager.changeOwnerAndGroupOfItem(at: tempFileURL, to: URL(fileURLWithPath: path))) == nil
                }
            } else {
                // I don't imagine this ever happening but in case it does, requesting authorization may be the better option
                needsAuthorization = true
            }
        }
    }
    return needsAuthorization
}
