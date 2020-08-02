//
//  SPUDownloaderDelegate.swift
//  SparkleDownloader
//
//  Created by Federico Ciardi on 26/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

@objc
protocol SPUDownloaderDelegate: NSObjectProtocol {
    // This is only invoked for persistent downloads
    func downloaderDidSetDestinationName(_ destinationName: String, temporaryDirection: String)

    // Under rare cases, this may be called more than once, in which case the current progress should be reset back to 0
    // This is only invoked for persistent downloads
    func downloaderDidReceiveExpectedContentLength(_ expectedContentLength: Int64)

    // This is only invoked for persistent downloads
    func downloaderDidReceiveDataOfLength(_ length: UInt64)

    // downloadData is nil if this is a persisent download, otherwise it's non-nil if it's a temporary download
    func downloaderDidFinishWithTemporaryDownloadData(_ downloadData: SPUDownloadData?)

    func downloaderDidFailWithError(_ error: NSError)
}
