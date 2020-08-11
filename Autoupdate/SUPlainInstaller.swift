//
//  SUPlainInstaller.swift
//  Sparkle
//
//  Created by Federico Ciardi on 10/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

class SUPlainInstaller: NSObject {
    
    private var host: SUHost
    private var bundlePath: String
    private(set) var installationPath: String
    
    /// - Parameter host: The current (old) bundle host
    /// - Parameter bundlePath: The path to the new bundle that will be installed.
    /// - Parameter installationPath: The path the new bundlePath will be installed to.
    init(with host: SUHost, bundlePath: String, installationPath: String) {
        super.init()
        self.host = host
        self.bundlePath = bundlePath
        self.installationPath = installationPath
    }
    
    private func bundleVersionAppropriateForFilename(from host: SUHost) -> String? {
        let bundleVersion = host.objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String
        var trimmedVersion = ""
        
        if let bundleVersion = bundleVersion {
            var validCharacters: CharacterSet = .alphanumerics
            validCharacters.formUnion(CharacterSet(charactersIn: ".-()"))
            
            trimmedVersion = bundleVersion.trimmingCharacters(in: validCharacters.inverted)
        }
        
        return trimmedVersion.count > 0 ? trimmedVersion : nil
    }
    
    private func startInstallation(to installationURL: URL?, fromUpdateAtURL newURL: URL?, with host: SUHost, progressBlock progress: ((Double) -> Void)?) throws {
        
        if let installationURL = installationURL, let newURL = newURL {
            progress?(1/10)
            
            let fileManager = SUFileManager()
            
            // Update the access time of our entire application before moving it into a temporary directory
            // The system periodically cleans up files by looking at the mod & access times, so we have to make sure they're up to date
            // They could be potentially be preserved when archiving an application, but also an update could just be sitting on the system for a long time
            // before being installed
            do {
                try fileManager.updateAccessTimeOfItem(at: newURL)
            } catch let error {
                SULog(.error, "Failed to recursively update new application's modification time before moving into temporary directory")
                throw error
            }
            
            // Create a temporary directory for our new app that resides on our destination's volume
            let preferredName = URL(fileURLWithPath: installationURL.lastPathComponent).deletingPathExtension().path + " (Incomplete Update)"
            let installationDirectory = installationURL.deletingLastPathComponent()
            
            let tempNewDirectoryURL: URL
            do {
                tempNewDirectoryURL = try fileManager.makeTemporaryDirectory(with: preferredName, appropriateFor: installationDirectory)
            } catch let error {
                SULog(.error, "Failed to make new temp directory")
                throw error
            }
            
            progress?(2/10)
            
            // Move the new app to our temporary directory
            let newURLLastPathComponent = newURL.lastPathComponent
            let newTempURL = tempNewDirectoryURL.appendingPathComponent(newURLLastPathComponent)
            do {
                try fileManager.moveItem(at: newURL, to: newTempURL)
            } catch let error {
                SULog(.error, "Failed to move the new app from \(newURL.path) to its temp directory at \(newTempURL.path)")
                try? fileManager.removeItem(at: tempNewDirectoryURL)
                throw error
            }
            
            progress?(3/10)
            
            // Release our new app from quarantine
            do {
                try fileManager.releaseItemFromQuarantine(at: newTempURL)
            } catch let error {
                // Not big enough of a deal to fail the entire installation
                SULog(.error, "Failed to release quarantine at \(newTempURL.path) with error \(error)")
            }
            
            progress?(4/10)
            
            let oldURL = URL(fileURLWithPath: host.bundlePath)
            
            // We must leave moving the app to its destination as the final step in installing it, so that
            // it's not possible our new app can be left in an incomplete state at the final destination
            
            do {
                try fileManager.changeOwnerAndGroupOfItem(at: newTempURL, to: oldURL)
            } catch let error {
                // But this is big enough of a deal to fail
                SULog(.error, "Failed to change owner and group of new app at \(newTempURL.path) to match old app at \(oldURL.path)")
                try? fileManager.removeItem(at: tempNewDirectoryURL)
                throw error
            }
            
            progress?(5/10)
            
            do {
                try fileManager.updateModificationAndAccessTimeOfItem(at: newTempURL)
            } catch let error {
                SULog(.error, "Failed to update modification and access time of new app at \(newTempURL.path)")
                SULog(.error, "Error: \(error)")
            }
            
            progress?(6/10)
            
            // Decide on a destination name we should use for the older app when we move it around the file system
            let oldDestinationName = URL(fileURLWithPath: oldURL.lastPathComponent).deletingPathExtension().path
            let oldDestinationNameWithPathExtension = oldURL.lastPathComponent
            
            // Create a temporary directory for our old app that resides on its volume
            let oldDirectoryURL = oldURL.deletingLastPathComponent()
            let tempOldDirectoryURL: URL
            do {
                tempOldDirectoryURL = try fileManager.makeTemporaryDirectory(with: oldDestinationName, appropriateFor: oldDirectoryURL)
            } catch let error {
                SULog(.error, "Failed to create temporary directory for old app at \(oldURL.path)")
                try? fileManager.removeItem(at: tempNewDirectoryURL)
                throw error
            }
            
            progress?(7/10)
            
            // Move the old app to the temporary directory
            let oldTempURL = tempOldDirectoryURL.appendingPathComponent(oldDestinationNameWithPathExtension)
            do {
                try fileManager.moveItem(at: oldURL, to: oldTempURL)
            } catch let error {
                SULog(.error, "Failed to move the old app at \(oldURL.path) to a temporary location at \(oldTempURL.path)")
                
                try? fileManager.removeItem(at: tempNewDirectoryURL)
                try? fileManager.removeItem(at: tempOldDirectoryURL)
                
                throw error
            }
            
            progress?(8/10)
            
            // Move the new app to its final destination
            do {
                try fileManager.moveItem(at: newTempURL, to: installationURL)
            } catch let error {
                SULog(.error, "Failed to move new app at \(newTempURL.path) to final destination \(installationURL.path)")
                
                // Forget about our updated app on failure
                try? fileManager.removeItem(at: tempNewDirectoryURL)
                
                // Attempt to restore our old app back the way it was on failure
                try? fileManager.moveItem(at: oldTempURL, to: oldURL)
                try? fileManager.removeItem(at: tempOldDirectoryURL)
                
                throw error
            }
            
            progress?(9/10)
            
            // Cleanup
            try? fileManager.removeItem(at: tempOldDirectoryURL)
            try? fileManager.removeItem(at: tempNewDirectoryURL)
            
            progress?(10/10)
            
        } else {
            // this really shouldn't happen but just in case
            SULog(.error, "Failed to perform installation because either installation URL (\(String(describing: installationURL))) or new URL (\(String(describing: newURL))) is nil")
            throw NSError(domain: SUSparkleErrorDomain, code: Int(SUError.SUInstallationError.rawValue), userInfo: [NSLocalizedDescriptionKey: "Failed to perform installation because the paths to install at and from are not valid"])
        }
        
    }
}

extension SUPlainInstaller: SUInstallerProtocol {
    var canInstallSilently: Bool {
        return true
    }
    
    func performInitialInstallation() throws {
        // Prevent malicious downgrades
        // Note that we may not be able to do this for package installations, hence this code being done here
        if !SPARKLE_AUTOMATED_DOWNGRADES {
            let hostVersion = host.version
            
            guard let bundle = Bundle(path: bundlePath) else { throw NSError() }
            let updateHost = SUHost(with: bundle)
            let updateVersion = updateHost.objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String
            
            let comparator = SUStandardVersionComparator() as SUVersionComparison
            // swiftlint:disable:next force_unwrapping
            guard updateVersion != nil, comparator.compareVersion(hostVersion, toVersion: updateVersion!) != .orderedDescending else {
                let updateVersion = updateHost.objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String
                throw NSError(
                    domain: SUSparkleErrorDomain,
                    code: Int(SUError.SUDowngradeError.rawValue),
                    userInfo: [NSLocalizedDescriptionKey: "For security reasons, updates that downgrade version of the application are not allowed. Refusing to downgrade app from version \(hostVersion) to \(String(describing: updateVersion)). Aborting update."]
                )
            }
        }
    }
    
    func performFinalInstallationProgressBlock(_ progressBlock: ((Double) -> Void)?) throws {
        // Note: we must do most installation work in the third stage due to relying on our application sitting in temporary directories.
        // It must not be possible for our update to sit in temporary directories for a very long time.
        try startInstallation(to: URL(fileURLWithPath: installationPath), fromUpdateAtURL: URL(fileURLWithPath: bundlePath), with: host, progressBlock: progressBlock)
    }
}
