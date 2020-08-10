//
//  SUGuidedPackageInstaller.swift
//  Sparkle
//
//  Created by Federico Ciardi on 10/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

/// # Sparkle Guided Installations
///
/// A guided installation allows Sparkle to download and install a package (pkg) or multi-package (mpkg) without user interaction.
///
/// The installer package is installed using macOS's built-in command line installer, `/usr/sbin/installer`. No installation interface is shown to the user.
///
/// A guided installation can be started by applications other than the application being replaced. This is particularly useful where helper applications or agents are used.


import Foundation
import System

class SUGuidedPackageInstaller: NSObject {
    
    private var packagePath: String
    private(set) var installationPath: String
    
    init(packagePath: String, installationPath: String) {
        super.init()
        self.packagePath = packagePath
        self.installationPath = installationPath
    }
}

extension SUGuidedPackageInstaller: SUInstallerProtocol {
    var canInstallSilently: Bool {
        return true
    }
    
    func performInitialInstallation(_ error: NSError) -> Bool {
        return true
    }
    
    func performFinalInstallationProgressBlock(_ progressionBlock: ((Double) -> Void)?) throws {
        // This command *must* be run as root
        let installerPath = "/usr/sbin/installer"
        
        let process = Process()
        process.launchPath = installerPath
        process.arguments = ["-pkg", packagePath, "-target", "/"]
        process.standardError = Pipe()
        process.standardOutput = Pipe()
        
        process.launch()
        process.waitUntilExit()
        guard process.terminationStatus == EXIT_SUCCESS else {
            throw NSError(domain: SUSparkleErrorDomain, code: Int(SUError.SUInstallationError.rawValue), userInfo: [NSLocalizedDescriptionKey: "Guided package installer returned non-zero exit status (\(process.terminationStatus))"])
        }
    }
}
