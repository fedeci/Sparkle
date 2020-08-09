//
//  SPUUpdaterDelegate.swift
//  Sparkle
//
//  Created by Federico Ciardi on 08/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

enum SPUUpdateCheck: Int {
    case userInitiated = 0
    case backgroundScheduled = 1
}

/// Provides methods to control the behavior of an SPUUpdater object.
@objc
protocol SPUUpdaterDelegate: NSObjectProtocol {

    /// Called when a background update will be scheduled after a delay.
    ///
    /// Automatic update checks need to be enabled for this to trigger.
    ///
    /// - Parameter delay: The delay until the next scheduled update will occur.
    ///
    /// - Parameter updater: The updater instance.
    @objc optional func updater(_ updater: SPUUpdater, willScheduleUpdateCheckAfterDelay delay: TimeInterval)

    /// Called when no updates will be scheduled in the future.
    ///
    /// This may later change if automatic update checks become enabled.
    ///
    /// - Parameter updater: updater The updater instance.
    @objc optional func updaterWillIdleSchedulingUpdates(_ updater: SPUUpdater)

    /// Returns whether to allow Sparkle to pop up.
    ///
    /// For example, this may be used to prevent Sparkle from interrupting a setup assistant.
    /// Alternatively, you may want to consider starting the updater after eg: the setup assistant finishes
    ///
    /// - Parameter updater: The updater instance.
    @objc optional func updaterMayCheckForUpdates(_ updater: SPUUpdater) -> Bool

    /// Returns additional parameters to append to the appcast URL's query string.
    ///
    /// This is potentially based on whether or not Sparkle will also be sending along the system profile.
    ///
    /// - Parameter updater: The updater instance.
    /// - Parameter sendingProfile: Whether the system profile will also be sent.
    ///
    /// - Returns: An array of dictionaries with keys: "key", "value", "displayKey", "displayValue", the latter two being specifically for display to the user.
    @objc optional func feedParametersForUpdater(_ updater: SPUUpdater, sendingSystemProfile: Bool) -> [[String: String]]

    /// Returns a custom appcast URL.
    ///
    /// Override this to dynamically specify the entire URL.
    /// Alternatively you may want to consider adding a feed parameter using `feedParametersForUpdater(:sendingSystemProfile:)`
    /// and having the server which appcast to serve.
    ///
    /// - Parameter updater: The updater instance.
    @objc optional func feedURLStringForUpdater(_ updater: SPUUpdater) -> String?

    /// Returns whether Sparkle should prompt the user about automatic update checks.
    ///
    /// Use this to override the default behavior.
    ///
    /// - Parameter updater: The updater instance.
    @objc optional func updaterShouldPromptForPermissionToCheckForUpdates(_ updater: SPUUpdater) -> Bool

    /// Called after Sparkle has downloaded the appcast from the remote server.
    ///
    /// Implement this if you want to do some special handling with the appcast once it finishes loading.
    ///
    /// - Parameter updater: The updater instance.
    /// - Parameter appcast: The appcast that was downloaded from the remote server.
    @objc optional func updater(_ updater: SPUUpdater, didFinishLoadingAppcast appcast: SUAppcast)

    /// Returns the item in the appcast corresponding to the update that should be installed.
    ///
    /// If you're using special logic or extensions in your appcast,
    /// implement this to use your own logic for finding a valid update, if any,
    /// in the given appcast.
    ///
    /// - Parameter appcast: The appcast that was downloaded from the remote server.
    /// - Parameter updater: The updater instance.
    /// - Returns: The best valid appcast item, or nil if you don't want to be delegated this task.
    @objc optional func bestValidUpdateInAppcast(_ appcast: SUAppcast, forUpdater updater: SPUUpdater) -> SUAppcastItem?

    /// Called when a valid update is found by the update driver.
    ///
    /// - Parameter updater: The updater instance.
    /// - Parameter item: The appcast item corresponding to the update that is proposed to be installed.
    @objc optional func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem)

    /// Called when a valid update is not found.
    ///
    /// - Parameter updater: The updater instance.
    @objc optional func updaterDidNotFindUpdate(_ updater: SPUUpdater)

    /// Returns whether the release notes (if available) should be downloaded after an update is found and shown.
    ///
    /// This is specifically for the releaseNotesLink element in the appcast.
    ///
    /// - Parameter updater: The updater instance.
    ///
    /// - Returns: `true` to download and show the release notes if available, otherwise `false`. The default behavior is `true`.
    @objc optional func updaterShouldDownloadReleaseNotes(_ updater: SPUUpdater) -> Bool

    /// Called immediately before downloading the specified update.
    ///
    /// - Parameter updater: The updater instance.
    /// - Parameter item: The appcast item corresponding to the update that is proposed to be downloaded.
    /// - Parameter request: The URL request that will be used to download the update.
    @objc optional func updater(_ updater: SPUUpdater, willDownloadUpdate item: SUAppcastItem, withRequest request: URLRequest)

    /// Called after the specified update failed to download.
    ///
    /// - Parameter updater: The updater instance.
    /// - Parameter item: The appcast item corresponding to the update that failed to download.
    /// - Parameter error: The error generated by the failed download.
    @objc optional func updater(_ updater: SPUUpdater, failedToDownloadUpdate item: SUAppcastItem, error: NSError)

    /// Called when the user clicks the cancel button while and update is being downloaded.
    ///
    /// - Parameter updater: The updater instance.
    @objc optional func userDidCancelDownload(_ updater: SPUUpdater)

    /// Called immediately before installing the specified update.
    ///
    /// - Parameter updater: The updater instance.
    /// - Parameter item: The appcast item corresponding to the update that is proposed to be installed.
    @objc optional func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem)

    /// Returns whether the relaunch should be delayed in order to perform other tasks.
    ///
    /// This is not called if the user didn't relaunch on the previous update,
    /// in that case it will immediately restart.
    ///
    /// This may also not be called if the application is not going to relaunch after it terminates.
    ///
    /// - Parameter updater: The updater instance.
    /// - Parameter item: The appcast item corresponding to the update that is proposed to be installed.
    /// - Parameter installHandler: The install handler that must be completed before continuing with the relaunch.
    ///
    /// - Returns: `true` to delay the relaunch until `installHandler` is invoked.
    @objc optional func updater(_ updater: SPUUpdater, shouldPostponeRelaunchForUpdate item: SUAppcastItem, untilInvokingBlock installHandler: () -> Void) -> Bool

    /// Returns whether the application should be relaunched at all.
    ///
    /// Some apps \b cannot be relaunched under certain circumstances.
    /// This method can be used to explicitly prevent a relaunch.
    ///
    /// - Parameter updater: The updater instance.
    /// - Returns: `true` if the updater should be relaunched, otherwise `false` if it shouldn't.
    @objc optional func updaterShouldRelaunchApplication(_ updater: SPUUpdater)

    /// Called immediately before relaunching.
    ///
    /// - Parameter updater: The updater instance.
    @objc optional func updaterWillRelaunchApplication(_ updater: SPUUpdater)

    /// Returns an object that compares version numbers to determine their arithmetic relation to each other.
    ///
    /// This method allows you to provide a custom version comparator.
    /// If you don't implement this method or return `nil`,
    /// the standard version comparator will be used. Note that the
    /// standard version comparator may be used during installation for preventing
    /// a downgrade, even if you provide a custom comparator here.
    ///
    /// - Parameter updater: The updater instance.
    /// - Returns: The custom version comparator or `nil` if you don't want to be delegated this task.
    @objc optional func versionComparatorForUpdater(_ updater: SPUUpdater) -> SUVersionComparison?

    /// Returns whether or not the updater should allow interaction from the installer
    ///
    /// Use this to override the default behavior which is to allow interaction with the installer.
    ///
    /// If interaction is allowed, then an authorization prompt may show up to the user if they do
    /// not curently have sufficient privileges to perform the installation of the new update.
    /// The installer may also show UI and progress when interaction is allowed.
    ///
    /// On the other hand, if interaction is not allowed, then an installation may fail if the user does not
    /// have sufficient privileges to perform the installation. In this case, the feed and update may not even be downloaded.
    ///
    /// Note this has no effect if the update has already been downloaded in the background silently and ready to be resumed.
    ///
    /// - Parameter updater: The updater instance.
    /// - Parameter updateCheck: The type of update check being performed.
    @objc optional func updater(_ updater: SPUUpdater, shouldAllowInstallerInteractionForUpdateCheck updateCheck: SPUUpdateCheck) -> Bool

    /// Returns the decryption password (if any) which is used to extract the update archive DMG.
    ///
    /// Return `nil` if no password should be used.
    ///
    /// - Parameter updater: The updater instance.
    /// - Returns: The password used for decrypting the archive, or `nil` if no password should be used.
    @objc optional func decryptionPasswordForUpdater(_ updater: SPUUpdater) -> String?

    /// Called when an update is scheduled to be silently installed on quit after downloading the update automatically.
    ///
    /// - Parameter updater: The updater instance.
    /// - Parameter item: The appcast item corresponding to the update that is proposed to be installed.
    /// - Parameter immediateInstallHandler: The install handler to immediately install the update. No UI interaction will be shown and the application will be relaunched after installation.
    /// - Returns: Return `true` if the delegate will handle installing the update or `false` if the updater should be given responsibility.
    ///
    /// If the updater is given responsibility, it can later remind the user an update is available if they have not terminated the application for a long time.
    /// Also if the updater is given responsibility and the update item is marked critical, the new update will be presented to the user immediately after.
    /// Even if the immediateInstallHandler is not invoked, the installer will attempt to install the update on termination.
    @objc optional func updater(_ updater: SPUUpdater, willInstallUpdateOnQuit item: SUAppcastItem, immediateInstallationBlock immediateInstallHandler: () -> Void) -> Bool

    /// Called after an update is aborted due to an error.
    ///
    /// - Parameter updater: The updater instance.
    /// - Parameter error: The error that caused the abort
    @objc optional func updater(_ updater: SPUUpdater, didAbortWithError error: NSError)

    /// Called after an update is aborted due to an error during an scheduled update check.
    ///
    /// - Parameter updater: The updater instance.
    /// - Parameter error: The error that caused the abort
    @objc optional func updater(_ updater: SPUUpdater, scheduledUpdateCheckDidAbortWithError error: NSError)
}
