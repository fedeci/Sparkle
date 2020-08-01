//
//  SPUMessageTypes.swift
//  Sparkle
//
//  Created by Federico Ciardi on 01/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

private let SPUAppcastItemArchiveKey = "SPUAppcastItemArchive"

// Tags added to the bundle identifier which is used as Mach service names
// These should be very short because length restrictions exist on earlier versions of macOS
private let SPARKLE_INSTALLER_TAG = "-spki"
private let SPARKLE_STATUS_TAG = "-spks"
private let SPARKLE_PROGRESS_TAG = "-spkp"
private let SPARKLE_PROGRESS_LAUNCH_INSTALLER_TAG = "-spkl"

// macOS 10.8 at least can't handle service names that are 64 characters or longer
// This was fixed some point after 10.8, but I'm not sure if it was fixed in 10.9 or 10.10 or 10.11
// If we knew when it was fixed, this could only be relevant to OS versions prior to that
private let MAX_SERVICE_NAME_LENGTH = 63

enum SPUInstallerMessageType: Int32 {
    case SPUInstallerNotStarted = 0
    case SPUExtractionStarted = 1
    case SPUExtractedArchiveWithProgress = 2
    case SPUArchiveExtractionFailed = 3
    case SPUValidationStarted = 4
    case SPUInstallationStartedStage1 = 5
    case SPUInstallationFinishedStage1 = 6
    case SPUInstallationFinishedStage2 = 7
    case SPUInstallationFinishedStage3 = 8
    case SPUUpdaterAlivePing = 9
}

enum SPUUpdaterMessageType: Int32 {
    case SPUInstallationData = 0
    case SPUSentUpdateAppcastItemData = 1
    case SPUResumeInstallationToStage2 = 2
    case SPUUpdaterAlivePong = 3
}

func SPUInstallerMessageTypeIsLegal(oldMessageType: SPUInstallerMessageType, newMessageType: SPUInstallerMessageType) -> Bool {
    var legal: Bool
    switch newMessageType {
    case .SPUInstallerNotStarted:
        legal = oldMessageType == .SPUInstallerNotStarted
    case .SPUExtractionStarted:
        legal = oldMessageType == .SPUInstallerNotStarted
    case .SPUExtractedArchiveWithProgress, .SPUArchiveExtractionFailed:
        legal = oldMessageType == .SPUExtractionStarted || oldMessageType == .SPUExtractedArchiveWithProgress
    case .SPUValidationStarted:
        legal = oldMessageType == .SPUExtractionStarted || oldMessageType == .SPUExtractedArchiveWithProgress
    case .SPUInstallationStartedStage1:
        legal = oldMessageType == .SPUValidationStarted
    case .SPUInstallationFinishedStage1:
        legal = oldMessageType == .SPUInstallationStartedStage1
    case .SPUInstallationFinishedStage2:
        legal = oldMessageType == .SPUInstallationFinishedStage1
    case .SPUInstallationFinishedStage3:
        legal = oldMessageType == .SPUInstallationFinishedStage2
    case .SPUUpdaterAlivePing:
        // Having this state being dependent on other installation states would make the complicate our logic
        // So just always allow this type of message
        legal = true
    }
    return legal
}

private func SPUServiceName(with tag: String, bundleIdentifier: String) -> String {
    let serviceName = bundleIdentifier + tag
    let length = min(serviceName.count, MAX_SERVICE_NAME_LENGTH)
    
    // If the service name is too long, cut off the beginning rather than cutting off the end
    // This should lead to a more unique name
    return (serviceName as NSString).substring(from: serviceName.count - length)
}

func SPUInstallerServiceName(for bundleIdentifier: String) -> String {
    return SPUServiceName(with: SPARKLE_INSTALLER_TAG, bundleIdentifier: bundleIdentifier)
}

func SPUStatusInfoServiceName(for bundleIdentifier: String) -> String {
    return SPUServiceName(with: SPARKLE_STATUS_TAG, bundleIdentifier: bundleIdentifier)
}

func SPUProgressAgentServiceName(for bundleIdentifier: String) -> String {
    return SPUServiceName(with: SPARKLE_PROGRESS_TAG, bundleIdentifier: bundleIdentifier)
}
