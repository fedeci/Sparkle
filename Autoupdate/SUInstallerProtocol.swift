//
//  SUInstallerProtocol.swift
//  Autoupdate
//
//  Created by Federico Ciardi on 10/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

protocol SUInstallerProtocol: NSObjectProtocol {
    
    // Indicates whether or not this installer can install the update silently in the background, without hindering the user
    // If this returns false, then the installation can fail if the user did not directly request for the install to occur.
    // Should be thread safe
    var canInstallSilently: Bool { get }
    
    // The destination and installation path of the bundle being updated
    var installationPath: String { get }
    
    // Any installation work can be done prior to user application being terminated and relaunched
    // No UI should occur during this stage (i.e, do not show package installer apps, etc..)
    // Should be able to be called from non-main thread
    func performInitialInstallation(_ error: NSError) -> Bool
    
    // Any installation work after the user application has has been terminated. This is where the final installation work can be done.
    // After this stage is done, the user application may be relaunched.
    // Should be able to be called from non-main thread
    func performFinalInstallationProgressBlock(_ progressionBlock: ((Double) -> Void)?, error: NSError) -> Bool
}
