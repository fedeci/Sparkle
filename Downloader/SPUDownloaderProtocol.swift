//
//  SPUDownloaderProtocol.swift
//  SparkleDownloader
//
//  Created by Federico Ciardi on 26/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

// The protocol that this service will vend as its API. This header file will also need to be visible to the process hosting the service.
@objc
protocol SPUDownloaderProtocol {
    
    func startPersistentDownloadWithRequest(_ request: SPUURLRequest, bundleIdentifier: String, desiredFilename: String)
    
    func startTemporaryDownloadWithRequest(_ request: SPUURLRequest)
    
    // Cancels any ongoing download
    func cancelDownload()
}

