//
//  SPUDownloaderProtocol.swift
//  SparkleDownloader
//
//  Created by Federico Ciardi on 26/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

@objc
protocol SPUDownloaderProtocol {
    func startPersistentDownloadWithRequest(_ request: SPUURLRequest, bundleIdentifier: String, desiredFilename: String)
    
    func startTemporaryDownloadWithRequest(_ request: SPUURLRequest)
    
    func cancelDownload()
}

