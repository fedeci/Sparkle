//
//  InstallerProgressAppController.swift
//  Installer Progress
//
//  Created by Federico Ciardi on 31/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Cocoa

private let SUTerminationTimeDelay = 0.3
private let CONNECTION_ACKNOWLEDGEMENT_TIMEOUT: Double = 7

@objcMembers
class InstallerProgressAppController: NSObject {
    var application: NSApplication?
    weak var delegate: InstallerProgressDelegate?
    private(set) var connection: NSXPCConnection?
    var connected: Bool?
    var repliedToRegistration: Bool?
    private(set) var hostBundle: Bundle?
    var statusInfo: StatusInfo?
    var submittedLauncherJob: Bool?
    var willTerminate: Bool?
    var applicationInitiallyAlive: Bool?
    var applicationBundle: Bundle?

    init(with application: NSApplication, arguments: [String], delegate: InstallerProgressDelegate) {
        super.init()

        if arguments.count != 3 {
            SULog(.error, "Error: Invalid number of arguments supplied: \(arguments)")
            cleanupAndExitWithStatus(Int(EXIT_FAILURE))
        }

        let hostBundlePath = arguments[1]
        if hostBundlePath.isEmpty {
            SULog(.error, "Error: Host bundle path length is 0")
            cleanupAndExitWithStatus(Int(EXIT_FAILURE))
        }

        hostBundle = Bundle(path: hostBundlePath)
        if hostBundle == nil {
            SULog(.error, "Error: Host bundle for target is nil")
            cleanupAndExitWithStatus(Int(EXIT_FAILURE))
        }

        guard let hostBundleIdentifier = hostBundle?.bundleIdentifier else {
            SULog(.error, "Error: Host bundle identifier for target is nil")
            cleanupAndExitWithStatus(Int(EXIT_FAILURE))
            return
        }

        // Note that we are connecting to the installer rather than the installer connecting to us
        // This difference is significant. We shouldn't have a model where the 'server' tries to connect to a 'client',
        // nor have a model where a process that runs at the highest level (the installer can run as root) tries to connect to a user level agent or process
        let systemDomain = (arguments[2] as NSString).boolValue
        let connectionOptions: NSXPCConnection.Options = systemDomain == true ? .privileged : []
        connection = NSXPCConnection(machServiceName: SPUProgressAgentServiceName(for: hostBundleIdentifier), options: connectionOptions)
        statusInfo = StatusInfo(hostBundleIdentifier: hostBundleIdentifier)

        application.delegate = self

        self.application = application
        self.delegate = delegate

        connection?.exportedInterface = NSXPCInterface(with: SPUInstallerAgentProtocol.self)
        connection?.exportedObject = self

        connection?.remoteObjectInterface = NSXPCInterface(with: SUInstallerAgentInitiationProtocol.self)

        connection?.interruptionHandler = { [weak self] in
            self?.connection?.invalidate()
        }

        connection?.invalidationHandler = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let exitStatus = self.repliedToRegistration == true ? EXIT_SUCCESS : EXIT_FAILURE
                if self.repliedToRegistration == false {
                    SULog(.error, "Error: Agent Invalidating without having the chance to reply to installer")
                }
                if self.willTerminate == false {
                    self.cleanupAndExitWithStatus(Int(exitStatus))
                }
            }
        }
    }

    func run() {
        application?.run()
    }

    func cleanupAndExitWithStatus(_ status: Int) {
        statusInfo?.invalidate()
        connection?.invalidate()

        // Remove the agent bundle; it is assumed this bundle is in a temporary/cache/support directory
        do {
            try FileManager.default.removeItem(atPath: Bundle.main.bundlePath)
        } catch let error as NSError {
            SULog(.error, "Couldn't remove agent bundle: \(error).")
        }

        exit(Int32(status))
    }

    private func startConnection() {
        statusInfo?.startListener()

        connection?.resume()
        (connection?.remoteObjectProxy as? SUInstallerAgentInitiationProtocol)?.connectionDidInitiateWithReply {
            DispatchQueue.main.async {
                self.connected = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + CONNECTION_ACKNOWLEDGEMENT_TIMEOUT) {
            if self.connected == false {
                SULog(.error, "Timeout error: failed to receive acknowledgement from installer")
                self.cleanupAndExitWithStatus(Int(EXIT_FAILURE))
            }
        }
    }

    private func runningApplicationsWith(bundle: Bundle?) -> [NSRunningApplication] {
        // Resolve symlinks otherwise when we compare file paths, we may not realize two paths that are represented differently are the same
        guard let bundle = bundle, let bundleIdentifier = bundle.bundleIdentifier else { return [] }

        let bundlePathComponents = URL(fileURLWithPath: (bundle.bundlePath as NSString).resolvingSymlinksInPath).pathComponents

        var matchedRunningApplications: [NSRunningApplication] = []
        let runningApplications = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)

        for runningApplication in runningApplications {
            // Comparing the URLs hasn't worked well for me in practice, so I'm comparing the file paths instead
            if let candidatePath = runningApplication.bundleURL?.resolvingSymlinksInPath().path, URL(fileURLWithPath: candidatePath).pathComponents == bundlePathComponents {
                matchedRunningApplications.append(runningApplication)
            }
        }
        return matchedRunningApplications
    }
}

extension InstallerProgressAppController: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        startConnection()
    }
}

extension InstallerProgressAppController: SPUInstallerAgentProtocol {
    func registerApplicationBundlePath(_ applicationBundlePath: String, reply: @escaping (NSNumber?) -> Void) {
        DispatchQueue.main.async {
            if !(self.willTerminate == true) {
                let applicationBundle = Bundle(path: applicationBundlePath)
                if applicationBundle == nil {
                    SULog(.error, "Error: Encountered invalid path for waiting termination: \(applicationBundlePath)")
                    self.cleanupAndExitWithStatus(Int(EXIT_FAILURE))
                }

                let runningApplications = self.runningApplicationsWith(bundle: applicationBundle)

                // We're just picking the first running application to send..
                // Ideally we'd send them all and have the installer monitor all of them but I don't want to deal with that complexity at the moment
                // Although that would still have the issue if another instance of the application launched during that duration
                // At the same time we don't want the installer to be over-reliant on us (the agent tool) in a way that could leave the installer as a zombie by accident
                // In other words, the installer should be monitoring for dead processes, not us
                // Lastly we don't handle monitoring or terminating processes from logged in users
                let firstRunningApplication = runningApplications.first
                let processIdentifier = firstRunningApplication == nil || firstRunningApplication?.isTerminated == true ? nil : NSNumber(nonretainedObject: firstRunningApplication?.processIdentifier)
                reply(processIdentifier)

                self.repliedToRegistration = true
                self.applicationBundle = applicationBundle
                self.applicationInitiallyAlive = processIdentifier != nil
            }
        }
    }

    func registerInstallationInfoData(_ installationInfoData: Data) {
        DispatchQueue.main.async {
            if self.statusInfo?.installationInfoData == nil {
                self.statusInfo?.installationInfoData = installationInfoData
            }
        }
    }

    func sendTerminationSignal() {
        DispatchQueue.main.async {
            if let bundleIdentifier = self.applicationBundle, self.willTerminate == false {
                // Note we are sending an Apple quit event, which gives the application or user a chance to delay or cancel the request, which is what we desire
                for runningApplication in self.runningApplicationsWith(bundle: bundleIdentifier) {
                    runningApplication.terminate()
                }
            }
        }
    }

    func showProgress() {
        DispatchQueue.main.async {
            if self.willTerminate == false {
                // Show app icon in the dock
                var psn = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: UInt32(kCurrentProcess))
                TransformProcessType(&psn, ProcessApplicationTransformState(kProcessTransformToForegroundApplication))

                // Note: the application icon needs to be set after showing the icon in the dock
                guard let hostBundle = self.hostBundle else {
                    SULog(.error, "Error: Host bundle for target is nil")
                    self.cleanupAndExitWithStatus(Int(EXIT_FAILURE))
                    return
                }
                let host = SUHost(with: hostBundle)
                self.application?.applicationIconImage = SUApplicationInfo.bestIcon(for: host)

                // Activate ourselves otherwise we will probably be in the background
                self.application?.activate(ignoringOtherApps: true)
                self.delegate?.installerProgressShouldDisplayWithHost(host)
            }
        }
    }

    func stopProgress() {
        DispatchQueue.main.async {
            // Dismiss any UI immediately
            self.delegate?.installerProgressShouldStop()
            self.delegate = nil

            // No need to broadcast status service anymore
            // In fact we shouldn't when we decide to relaunch the update
            self.statusInfo?.invalidate()
            self.statusInfo = nil
        }
    }

    func relaunchPath(_ requestedPathToRelaunch: String) {
        DispatchQueue.main.async {
            if let bundlePath = self.applicationBundle?.bundlePath, self.willTerminate == false, self.applicationInitiallyAlive == true {
                // If the normalized setting is not enabled, we shouldn't trust the relaunch path input that is being passed to us
                // because we already have the application path to relaunch, and we verified that it was running before

                var pathToRelaunch: String
                if SPARKLE_NORMALIZE_INSTALLED_APPLICATION_NAME {
                    pathToRelaunch = requestedPathToRelaunch
                } else {
                    pathToRelaunch = bundlePath
                }

                // We should at least make sure we're opening a bundle however
                let relaunchBundle = Bundle(path: pathToRelaunch)
                if relaunchBundle == nil {
                    SULog(.error, "Error: Encountered invalid path to relaunch: \(String(describing: pathToRelaunch))")
                    self.cleanupAndExitWithStatus(Int(EXIT_FAILURE))
                }

                // We only launch applications, but I'm not sure how reliable -launchApplicationAtURL:options:config: is so we're not using it
                // Eg: http://www.openradar.me/10952677
                if !NSWorkspace.shared.openFile(pathToRelaunch) {
                    SULog(.error, "Error: Failed to relaunch bundle at \(pathToRelaunch)")
                }

                // Delay termination for a little bit to better increase the chance the updated application when relaunched will be the frontmost application
                // This is related to macOS activation issues when terminating a frontmost application happens right before launching another app
                self.willTerminate = true
                DispatchQueue.main.asyncAfter(deadline: .now() + SUTerminationTimeDelay) {
                    self.cleanupAndExitWithStatus(Int(EXIT_SUCCESS))
                }
            }
        }
    }
}
