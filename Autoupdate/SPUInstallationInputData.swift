//
//  SPUInstallationInputData.swift
//  Sparkle
//
//  Created by Federico Ciardi on 09/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

private let SURelaunchPathKey = "SURelaunchPath"
private let SUHostBundlePathKey = "SUHostBundlePath"
private let SUUpdateDirectoryPathKey = "SUUpdateDirectoryPath"
private let SUDownloadNameKey = "SUDownloadName"
private let SUSignaturesKey = "SUSignatures"
private let SUDecryptionPasswordKey = "SUDecryptionPassword"
private let SUInstallationTypeKey = "SUInstallationType"

class SPUInstallationInputData: NSObject {
    
    private(set) var relaunchPath: String
    private(set) var hostBundlePath: String
    private(set) var updateDirectoryPath: String
    private(set) var downloadName: String
    private(set) var installationType: String
    private(set) var signatures: SUSignatures
    private(set) var decryptionPassword: String?

    // relaunchPath - path to application bundle to relaunch and listen for termination
    // hostBundlePath - path to host bundle to update & replace
    // updateDirectoryPath - path to update directory (i.e, temporary directory containing the new update archive)
    // downloadName - name of update archive in update directory
    // signatures - signatures for the update that came from the appcast item
    // decryptionPassword - optional decryption password for dmg archives
    init(
        relaunchPath: String,
        hostBundlePath: String,
        updateDirectoryPath: String,
        downloadName: String,
        installationType: String,
        signatures: SUSignatures,
        decryptionPassword: String?
    ) {
        super.init()
        self.relaunchPath = relaunchPath
        self.hostBundlePath = hostBundlePath
        self.updateDirectoryPath = updateDirectoryPath
        self.downloadName = downloadName
        self.installationType = installationType
        self.signatures = signatures
        self.decryptionPassword = decryptionPassword
    }
    
    required convenience init?(coder: NSCoder) {
        guard let relaunchPath = coder.decodeObject(forKey: SURelaunchPathKey) as? String else { return nil }
        
        guard let hostBundlePath = coder.decodeObject(forKey: SUHostBundlePathKey) as? String else { return nil }
        
        guard let updateDirectoryPath = coder.decodeObject(forKey: SUUpdateDirectoryPathKey) as? String else { return nil }
        
        guard let downloadName = coder.decodeObject(forKey: SUDownloadNameKey) as? String else { return nil }
        
        guard let installationType = coder.decodeObject(forKey: SUInstallationTypeKey) as? String,
              SPUValidInstallationType(installationType)
        else { return nil }
        
        guard let signatures = coder.decodeObject(forKey: SUSignaturesKey) as? SUSignatures else { return nil }
        
        let decryptionPassword = coder.decodeObject(forKey: SUDecryptionPasswordKey) as? String
        
        self.init(
            relaunchPath: relaunchPath,
            hostBundlePath: hostBundlePath,
            updateDirectoryPath: updateDirectoryPath,
            downloadName: downloadName,
            installationType: installationType,
            signatures: signatures,
            decryptionPassword: decryptionPassword
        )
    }
}

extension SPUInstallationInputData: NSSecureCoding {
    static var supportsSecureCoding: Bool {
        return true
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(relaunchPath, forKey: SURelaunchPathKey)
        coder.encode(hostBundlePath, forKey: SUHostBundlePathKey)
        coder.encode(updateDirectoryPath, forKey: SUUpdateDirectoryPathKey)
        coder.encode(installationType, forKey: SUInstallationTypeKey)
        coder.encode(downloadName, forKey: SUDownloadNameKey)
        coder.encode(signatures, forKey: SUSignaturesKey)
        coder.encode(decryptionPassword, forKey: SUDecryptionPasswordKey)
    }
}
