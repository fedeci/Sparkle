//
//  SPUDownloader.swift
//  SparkleDownloader
//
//  Created by Federico Ciardi on 02/01/21.
//  Copyright © 2021 Sparkle Project. All rights reserved.
//

import Foundation

enum SPUDownloadMode: UInt {
    case persistent
    case temporary
}

let SUDownloadingReason = "Downloading update related file"

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
class SPUDownloader: NSObject {
    // Due to XPC remote object reasons, this delegate is strongly referenced
    // Invoke cleanup when done with this instance
    var delegate: SPUDownloaderDelegate?
    private var download: URLSessionDownloadTask?
    private var downloadSession: URLSession?
    private var bundleIdentifier: String?
    private var desiredFilename: String?
    private var downloadFilename: String?
    private var disabledAutomaticTermination: Bool?
    private var mode: SPUDownloadMode?
    private var receivedExpectedBytes: Bool?
    
    init(withDelegate delegate: SPUDownloaderDelegate) {
        super.init()
        self.delegate = delegate
    }
    
    func startDownloadWithRequest(_ request: SPUURLRequest) {
        downloadSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        download = downloadSession?.downloadTask(with: request.request)
        download?.resume()
    }
    
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
        
        var downloadData: SPUDownloadData? = nil
        if let downloadFilename = downloadFilename, mode == .temporary {
            if let data = NSData(contentsOfFile: downloadFilename) as Data? {
                let response = download?.response
                assert(response != nil)
                
                if let responseURL = response?.url ?? download?.currentRequest?.url ?? download?.originalRequest?.url {
                    downloadData = SPUDownloadData(data: data, url: responseURL, textEncodingName: response?.textEncodingName, mimeType: response?.mimeType)
                }
            }
        }
        
        download = nil
        
        switch mode {
        case .temporary:
            guard let downloadData = downloadData else {
                let error = NSError(domain: SUSparkleErrorDomain, code: Int(SUError.downloadError.rawValue), userInfo: [NSLocalizedDescriptionKey: "Failed to read temporary downloaded data from \(String(describing: downloadFilename))"])
                delegate?.downloaderDidFailWithError(error as Error)
                return
            }
            delegate?.downloaderDidFinishWithTemporaryDownloadData(downloadData)
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

extension SPUDownloader: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if mode == .temporary {
            downloadFilename = location.path
            downloadDidFinish()
            return
        }
        
        guard let bundleIdentifier = bundleIdentifier else { return }
        let rootPersistentDownloadCachePath = URL(fileURLWithPath: SPULocalCacheDirectory.cachePath(forBundleIdentifier: bundleIdentifier)).appendingPathComponent("PersistentDownloads").path
        SPULocalCacheDirectory.removeOldItems(inDirectory: rootPersistentDownloadCachePath)
        
        guard let tempDir = SPULocalCacheDirectory.createUniqueDirectory(inDirectory: rootPersistentDownloadCachePath) else {
            // Okay, something's really broken with this user's file structure.
            download?.cancel()
            download = nil
            
            let error = NSError(domain: SUSparkleErrorDomain, code: Int(SUError.temporaryDirectoryError.rawValue), userInfo: [NSLocalizedDescriptionKey: "Can't make a temporary directory for the update download."])
            delegate?.downloaderDidFailWithError(error as Error)
            return
        }
        
        guard let downloadFilename = desiredFilename else { return }
        let downloadFilenameDirectory = URL(fileURLWithPath: tempDir).appendingPathComponent(downloadFilename).path
        do {
            try FileManager.default.createDirectory(atPath: downloadFilenameDirectory, withIntermediateDirectories: false, attributes: nil)
        } catch {
            let error = NSError(domain: SUSparkleErrorDomain, code: Int(SUError.temporaryDirectoryError.rawValue), userInfo: [NSLocalizedDescriptionKey: "Can't make a download file name \(downloadFilename) directory inside temporary directory for the update download at \(downloadFilenameDirectory)."])
            delegate?.downloaderDidFailWithError(error as Error)
            return
        }
        // location.lastPathComponent likely contains nothing useful to identify the file (e.g. CFNetworkDownload_87LVIz.tmp)
        let name = download?.response?.suggestedFilename ?? location.lastPathComponent
        let toPath = URL(fileURLWithPath: downloadFilenameDirectory).appendingPathComponent(name).path
        let fromPath = location.path
        
        do {
            try FileManager.default.moveItem(atPath: fromPath, toPath: toPath)
        } catch let error {
            delegate?.downloaderDidFailWithError(error)
            return
        }
        
        self.downloadFilename = toPath
        delegate?.downloaderDidSetDestinationName(name, temporaryDirectory: downloadFilenameDirectory)
        downloadDidFinish()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if mode == .persistent && totalBytesWritten > 0 && receivedExpectedBytes == false {
            receivedExpectedBytes = true
            delegate?.downloaderDidReceiveExpectedContentLength(totalBytesWritten)
        }
        
        if mode == .persistent && bytesWritten >= 0 {
            delegate?.downloaderDidReceiveDataOfLength(UInt64(bytesWritten))
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        download = nil
        if let delegate = delegate, let error = error {
            delegate.downloaderDidFailWithError(error)
        }
        cleanup()
    }
    
    
}

extension SPUDownloader: SPUDownloaderProtocol {
    // Don't implement dealloc - make the client call cleanup, which is the only way to remove the reference cycle from the delegate anyway
    func startPersistentDownloadWithRequest(_ request: SPUURLRequest, bundleIdentifier: String, desiredFilename: String) {
        DispatchQueue.main.async { [self] in
            if download == nil && delegate != nil {
                // Prevent service from automatically terminating while downloading the update asynchronously without any reply blocks
                ProcessInfo.processInfo.disableAutomaticTermination(SUDownloadingReason)
                disabledAutomaticTermination = true
                
                mode = .persistent
                self.desiredFilename = desiredFilename
                self.bundleIdentifier = bundleIdentifier
                
                startDownloadWithRequest(request)
            }
        }
    }
    
    func startTemporaryDownloadWithRequest(_ request: SPUURLRequest) {
        DispatchQueue.main.async { [self] in
            if download == nil && delegate != nil {
                // Prevent service from automatically terminating while downloading the update asynchronously without any reply blocks
                ProcessInfo.processInfo.disableAutomaticTermination(SUDownloadingReason)
                disabledAutomaticTermination = true
                
                self.mode = .temporary
                startDownloadWithRequest(request)
            }
        }
    }
    
    func cancelDownload() {
        cleanup()
    }
}
