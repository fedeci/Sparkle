//
//  SUPackageInstaller.swift
//  Autoupdate
//
//  Created by Federico Ciardi on 10/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

private let SUOpenUtilityPath = "/usr/bin/open"
// This is the deprecated package installation type, aka the "interactive" package installer
// For a more supported package installation, see SUGuidedPackageInstaller
class SUPackageInstaller: NSObject {
    
    private var packagePath: String
    private(set) var installationPath: String
    
    init(packagePath: String, installationPath: String) {
        super.init()
        self.packagePath = packagePath
        self.installationPath = installationPath
    }
}

extension SUPackageInstaller: SUInstallerProtocol {
    var canInstallSilently: Bool {
        return false
    }
    
    func performInitialInstallation() throws {
        guard FileManager.default.fileExists(atPath: SUOpenUtilityPath) else {
            throw NSError(domain: SUSparkleErrorDomain, code: Int(SUError.SUMissingInstallerToolError.rawValue), userInfo: [NSLocalizedDescriptionKey: "Couldn't find Apple's installer tool!"])
        }
    }
    
    func performFinalInstallationProgressBlock(_ progressBlock: ((Double) -> Void)?) throws {
        // Run installer using the "open" command to ensure it is launched in front of current application.
        // -W = wait until the app has quit.
        // -n = Open another instance if already open.
        // -b = app bundle identifier
        let args = ["-W", "-n", "-b", "com.apple.installer", packagePath]
        
        // Known bug: if the installation fails or is canceled, Sparkle goes ahead and restarts, thinking everything is fine.
        let installer = Process.launchedProcess(launchPath: SUOpenUtilityPath, arguments: args)
        installer.waitUntilExit()
        
        guard installer.terminationStatus == EXIT_SUCCESS else {
            throw NSError(domain: SUSparkleErrorDomain, code: Int(SUError.SUInstallationError.rawValue), userInfo: [NSLocalizedDescriptionKey: "Package installer returned non-zero exit status (\(installer.terminationStatus))"])
        }
    }
}
