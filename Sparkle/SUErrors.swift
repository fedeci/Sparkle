//
//  SUErrors.swift
//  Sparkle
//
//  Created by Federico Ciardi on 26/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

enum SUError: OSStatus {
    // Configuration phase errors
    case SUNoPublicDSAFoundError = 0001
    case SUInsufficientSigningError = 0002
    case SUInsecureFeedURLError = 0003
    case SUInvalidFeedURLError = 0004
    case SUInvalidUpdaterError = 0005
    case SUInvalidHostBundleIdentifierError = 0006
    case SUInvalidHostVersionError = 0007

    // Appcast phase errors.
    case SUAppcastParseError = 1000
    case SUNoUpdateError = 1001
    case SUAppcastError = 1002
    case SURunningFromDiskImageError = 1003
    case SUResumeAppcastError = 1004
    case SURunningTranslocated = 1005

    // Download phase errors.
    case SUTemporaryDirectoryError = 2000
    case SUDownloadError = 2001

    // Extraction phase errors.
    case SUUnarchivingError = 3000
    case SUSignatureError = 3001

    // Installation phase errors.
    case SUFileCopyFailure = 4000
    case SUAuthenticationFailure = 4001
    case SUMissingUpdateError = 4002
    case SUMissingInstallerToolError = 4003
    case SURelaunchError = 4004
    case SUInstallationError = 4005
    case SUDowngradeError = 4006
    case SUInstallationCanceledError = 4007
    case SUInstallationAuthorizeLaterError = 4008
    case SUNotAllowedInteractionError = 4009

    // API misuse errors.
    case SUIncorrectAPIUsageError = 5000
}
