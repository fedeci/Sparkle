//
//  SPUURLDownload.swift
//  Sparkle
//
//  Created by Federico Ciardi on 26/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

@objcMembers
class SPUTemporaryDownloaderDelegate: NSObject {
    var completionBlock: ((SPUDownloadData?, NSError?) -> Void)?

    init(completionBlock: @escaping (SPUDownloadData?, NSError?) -> Void) {
        self.completionBlock = completionBlock
    }
}

extension SPUTemporaryDownloaderDelegate: SPUDownloaderDelegate {
    func downloaderDidFinishWithTemporaryDownloadData(_ downloadData: SPUDownloadData?) {
        if let completionBlock = completionBlock {
            completionBlock(downloadData, nil)
            self.completionBlock = nil
        }
    }

    func downloaderDidFailWithError(_ error: NSError) {
        if let completionBlock = completionBlock {
            completionBlock(nil, error)
            self.completionBlock = nil
        }
    }
}

func SPUDownloadURL(with request: URLRequest, completionBlock: (SPUDownloadData?, NSError?) -> Void) {
    var downloader: SPUDownloaderProtocol?
    var connection: NSXPCConnection?
    var retrievedDownloadResult = false

    let temporaryDownloaderDelegate = SPUTemporaryDownloaderDelegate(completionBlock: { downloadData, error in
        DispatchQueue.main.async {
            if !retrievedDownloadResult {
                retrievedDownloadResult = true
                connection?.invalidate()

                if downloadData == nil || downloadData?.data == nil {
                    completionBlock(nil, error)
                } else {
                    completionBlock(downloadData, nil)
                }
            }
        }
    })

    if !SPUXPCServiceExists(SPUDownloaderBundleIdentifier) {
        downloader = SPUDownloader(withDelegate: temporaryDownloaderDelegate)
    } else {
        connection = NSXPCConnection(serviceName: SPUDownloaderBundleIdentifier)
        connection?.remoteObjectInterface = NSXPCInterface(with: SPUDownloaderProtocol.self)
        connection?.exportedInterface = NSXPCInterface(with: SPUDownloaderDelegate.self)
        connection?.exportedObject = temporaryDownloaderDelegate

        connection?.interruptionHandler = {
            DispatchQueue.main.async {
                // Retain cycle
                if !retrievedDownloadResult {
                    connection?.invalidate()
                }
            }
        }

        connection?.invalidationHandler = {
            DispatchQueue.main.async {
                if !retrievedDownloadResult {
                    completionBlock(nil, NSError(domain: SUSparkleErrorDomain, code: Int(SUError.SUDownloadError.rawValue), userInfo: nil))
                }

                // Break the retain cycle
                connection?.interruptionHandler = nil
                connection?.invalidationHandler = nil
            }
        }

        connection?.resume()

        downloader = connection?.remoteObjectProxy as? SPUDownloaderProtocol

        if let request = SPUURLRequest.URLRequestWithRequest(request) {
            downloader?.startTemporaryDownloadWithRequest(request)
        } else {
            #warning("Handle error")
        }
    }
}
