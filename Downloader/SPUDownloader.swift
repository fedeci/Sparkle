//
//  SPUDownloader.swift
//  Sparkle
//
//  Created by Federico Ciardi on 26/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

enum SPUDownloadMode: UInt {
    case persistent
    case temporary
}

private let SUDownloadingReason = "Downloading update related file"

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@objcMembers
class SPUDownloader: NSObject {
    // swiftlint:disable:next weak_delegate
    var delegate: SPUDownloaderDelegate? // Delegate is intentionally strongly referenced
    var download: URLSessionDownloadTask?
    var downloadSession: URLSession?
    var bundleIdentifier: String?
    var desiredFilename: String?
    var downloadFilename: String?
    var disabledAutomaticTermination: Bool?
    var mode: SPUDownloadMode?
    var receivedExpectedBytes: Bool?

    // Due to XPC remote object reasons, this delegate is strongly referenced
    // Invoke cleanup when done with this instance
    init(with delegate: SPUDownloaderDelegate) {
        super.init()
        self.delegate = delegate
    }

    func startDownloadWithRequest(_ request: SPUURLRequest) {
        downloadSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
        download = downloadSession?.downloadTask(with: request.request)
        download?.resume()
    }

    // Don't implement deinit - make the client call cleanup, which is the only way to remove the reference cycle from the delegate anyway

    func enableAutomaticTermination() {
        if disabledAutomaticTermination == true {
            ProcessInfo.processInfo.enableAutomaticTermination(SUDownloadingReason)
            disabledAutomaticTermination = false
        }
    }

    func cleanup() {
        enableAutomaticTermination()
        download?.cancel()
        downloadSession?.finishTasksAndInvalidate()
        download = nil
        downloadSession = nil
        delegate = nil

        if let downloadFilename = downloadFilename, mode == .temporary {
            try? FileManager.default.removeItem(atPath: downloadFilename)
            self.downloadFilename = nil
        }
    }

    func downloadDidFinish() {
        assert(downloadFilename != nil)

        var downloadData: SPUDownloadData?
        if mode == .temporary {
            if let downloadFilename = downloadFilename, let data = NSData(contentsOfFile: downloadFilename) as Data? {
                let response = download?.response
                assert(response != nil)

                if let responseURL = response?.url ?? download?.currentRequest?.url ?? download?.originalRequest?.url {
                    downloadData = SPUDownloadData(data: data, URL: responseURL, textEncodingName: response?.textEncodingName, MIMEType: response?.mimeType)
                }
            }

            download = nil

            switch mode {
            case .temporary:
                if let downloadData = downloadData {
                    delegate?.downloaderDidFinishWithTemporaryDownloadData(downloadData)
                } else {
                    let error = NSError(domain: SUSparkleErrorDomain, code: Int(SUError.SUDownloadError.rawValue), userInfo: [
                        NSLocalizedDescriptionKey: "Failed to read temporary downloaded data from \(String(describing: downloadFilename))"
                    ])
                    delegate?.downloaderDidFailWithError(error)
                }
                break
            case .persistent:
                delegate?.downloaderDidFinishWithTemporaryDownloadData(nil)
                break
            default:
                break
            }

            cleanup()
        }
    }
}

extension SPUDownloader: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if mode == .temporary {
            downloadFilename = location.path
            downloadDidFinish() // file is already in a system temp dir
        } else {
            // Remove our old caches path so we don't start accumulating files in there
            guard let bundleIdentifier = bundleIdentifier,
                  let cachePath = SPULocalCacheDirectory.cachePath(for: bundleIdentifier)
            else { return }

            let rootPersistentDownloadCachePath = URL(fileURLWithPath: cachePath).appendingPathComponent("PersistentDownloads").absoluteString
            SPULocalCacheDirectory.removeOldItems(in: rootPersistentDownloadCachePath)

            let tempDir = SPULocalCacheDirectory.createUniqueDirectory(in: rootPersistentDownloadCachePath)
            if tempDir == nil {
                // Okay, something's really broken with this user's file structure.
                download?.cancel()
                download = nil

                let error = NSError(domain: SUSparkleErrorDomain, code: Int(SUError.SUTemporaryDirectoryError.rawValue), userInfo: [
                    NSLocalizedDescriptionKey: "Can't make a temporary directory for the update download at \(String(describing: tempDir))."
                ])

                delegate?.downloaderDidFailWithError(error)
            } else {
                guard let downloadFileName = desiredFilename else { return }
                // swiftlint:disable:next force_unwrapping
                let downloadFileNameDirectory = URL(fileURLWithPath: tempDir!).appendingPathComponent(downloadFileName)

                do {
                    try FileManager.default.createDirectory(at: downloadFileNameDirectory, withIntermediateDirectories: false, attributes: nil)
                } catch {
                    let error = NSError(domain: SUSparkleErrorDomain, code: Int(SUError.SUTemporaryDirectoryError.rawValue), userInfo: [
                        NSLocalizedDescriptionKey: "Can't make a download file name \(downloadFileName) directory inside temporary directory for the update download at \(downloadFileNameDirectory)."
                    ])
                    delegate?.downloaderDidFailWithError(error)
                    return
                }

                // location.lastPathComponent likely contains nothing useful to identify the file (e.g. CFNetworkDownload_87LVIz.tmp)
                let name = download?.response?.suggestedFilename ?? location.lastPathComponent
                let toPath = downloadFileNameDirectory.appendingPathComponent(name).absoluteString
                let fromPath = location.path // suppress moveItemAtPath: non-null warning

                do {
                    try FileManager.default.moveItem(atPath: fromPath, toPath: toPath)
                    downloadFilename = toPath
                    delegate?.downloaderDidSetDestinationName(name, temporaryDirection: downloadFileNameDirectory.absoluteString)
                    downloadDidFinish()
                } catch let error as NSError {
                    delegate?.downloaderDidFailWithError(error)
                    return
                }
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if mode == .persistent && totalBytesExpectedToWrite > 0 && receivedExpectedBytes == false {
            receivedExpectedBytes = true
            delegate?.downloaderDidReceiveExpectedContentLength(totalBytesExpectedToWrite)
        }

        if mode == .temporary && bytesWritten >= 0 {
            delegate?.downloaderDidReceiveDataOfLength(UInt64(bytesWritten))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        download = nil
        delegate?.downloaderDidFailWithError((error as NSError?) ?? NSError())
        cleanup()
    }
}

extension SPUDownloader: SPUDownloaderProtocol {
    func startPersistentDownloadWithRequest(_ request: SPUURLRequest, bundleIdentifier: String, desiredFilename: String) {
        DispatchQueue.main.async {
            if self.download == nil && self.delegate != nil {
                // Prevent service from automatically terminating while downloading the update asynchronously without any reply blocks
                ProcessInfo.processInfo.disableAutomaticTermination(SUDownloadingReason)
                self.disabledAutomaticTermination = true

                self.mode = .persistent
                self.desiredFilename = desiredFilename
                self.bundleIdentifier = bundleIdentifier

                self.startDownloadWithRequest(request)
            }
        }
    }

    func startTemporaryDownloadWithRequest(_ request: SPUURLRequest) {
        DispatchQueue.main.async {
            if self.download == nil && self.delegate != nil {
                // Prevent service from automatically terminating while downloading the update asynchronously without any reply blocks
                ProcessInfo.processInfo.disableAutomaticTermination(SUDownloadingReason)
                self.disabledAutomaticTermination = true

                self.mode = .temporary
                self.startDownloadWithRequest(request)
            }
        }
    }

    func cancelDownload() {
        cleanup()
    }
}
