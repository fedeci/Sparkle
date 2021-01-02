//
//  SPUDownloaderProtocol.swift
//  SparkleDownloader
//
//  Created by Federico Ciardi on 02/01/21.
//  Copyright © 2021 Sparkle Project. All rights reserved.
//

import Foundation

// The protocol that this service will vend as its API. This header file will also need to be visible to the process hosting the service.
protocol SPUDownloaderProtocol {
    func startPersistentDownloadWithRequest(_ request: SPUURLRequest, bundleIdentifier: String, desiredFilename: String)
    
    func startTemporaryDownloadWithRequest(_ request: SPUURLRequest)
    
    // Cancels any ongoing download
    func cancelDownload()
}
