//
//  SUConstants.swift
//  Sparkle
//
//  Created by Federico Ciardi on 26/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

#if !DEBUG
let DEBUG = false
#endif

// Define some minimum intervals to avoid DoS-like checking attacks
let SUMinimumUpdateCheckInterval: TimeInterval = DEBUG ? 60 : (60 * 60)
let SUDefaultUpdateCheckInterval: TimeInterval = DEBUG ? 60 : (60 * 60 * 24)

// If the update has already been automatically downloaded, we normally don't want to bug the user about the update
// However if the user has gone a very long time without quitting an application, we will bug them
// This is the time interval for a "week" it doesn't matter that this measure is imprecise.
let SUImpatientUpdateCheckInterval: TimeInterval = DEBUG ? (60 * 2) : (60 * 60 * 24 * 7)


let SPUSparkleBundleIdentifier = "org.sparkle-project.Sparkle"
let SPUDownloaderBundleIdentifier = "org.sparkle-project.Downloader"

let SUAppcastAttributeValueMacOS = "macos"

let SUTechnicalErrorInformationKey = "SUTechnicalErrorInformation"

let SUFeedURLKey = "SUFeedURL"
let SUHasLaunchedBeforeKey = "SUHasLaunchedBefore"
let SUUpdateRelaunchingMarkerKey = "SUUpdateRelaunchingMarker"
let SUShowReleaseNotesKey = "SUShowReleaseNotes"
let SUSkippedVersionKey = "SUSkippedVersion"
let SUScheduledCheckIntervalKey = "SUScheduledCheckInterval"
let SULastCheckTimeKey = "SULastCheckTime"
let SUExpectsDSASignatureKey = "SUExpectsDSASignature"
let SUExpectsEDSignatureKey = "SUExpectsEDSignatureKey"
let SUPublicDSAKeyKey = "SUPublicDSAKey"
let SUPublicDSAKeyFileKey = "SUPublicDSAKeyFile"
let SUPublicEDKeyKey = "SUPublicEDKey"
let SUAutomaticallyUpdateKey = "SUAutomaticallyUpdate"
let SUAllowsAutomaticUpdatesKey = "SUAllowsAutomaticUpdates"
let SUEnableSystemProfilingKey = "SUEnableSystemProfiling"
let SUEnableAutomaticChecksKey = "SUEnableAutomaticChecks"
let SUSendProfileInfoKey = "SUSendProfileInfo"
let SULastProfileSubmitDateKey = "SULastProfileSubmissionDate"
let SUPromptUserOnFirstLaunchKey = "SUPromptUserOnFirstLaunch"
let SUEnableJavaScriptKey = "SUEnableJavaScript"
let SUFixedHTMLDisplaySizeKey = "SUFixedHTMLDisplaySize"
let SUDefaultsDomainKey = "SUDefaultsDomain"
/**
 * Error domain used by Sparkle
 */
let SUSparkleErrorDomain = "SUSparkleErrorDomain"

let SUAppendVersionNumberKey = "SUAppendVersionNumber"
let SUEnableAutomatedDowngradesKey = "SUEnableAutomatedDowngrades"
let SUNormalizeInstalledApplicationNameKey = "SUNormalizeInstalledApplicationName"
let SURelaunchToolNameKey = "SURelaunchToolName"

let SUAppcastAttributeDeltaFrom = "sparkle:deltaFrom"
let SUAppcastAttributeDSASignature = "sparkle:dsaSignature"
let SUAppcastAttributeEDSignature = "sparkle:edSignature"
let SUAppcastAttributeShortVersionString = "sparkle:shortVersionString"
let SUAppcastAttributeVersion = "sparkle:version"
let SUAppcastAttributeOsType = "sparkle:os"
let SUAppcastAttributeInstallationType = "sparkle:installationType"

let SUAppcastElementCriticalUpdate = "sparkle:criticalUpdate"
let SUAppcastElementDeltas = "sparkle:deltas"
let SUAppcastElementMinimumSystemVersion = "sparkle:minimumSystemVersion"
let SUAppcastElementMaximumSystemVersion = "sparkle:maximumSystemVersion"
let SUAppcastElementReleaseNotesLink = "sparkle:releaseNotesLink"
let SUAppcastElementTags = "sparkle:tags"

let SURSSAttributeURL = "url"
let SURSSAttributeLength = "length"

let SURSSElementDescription = "description"
let SURSSElementEnclosure = "enclosure"
let SURSSElementLink = "link"
let SURSSElementPubDate = "pubDate"
let SURSSElementTitle = "title"
