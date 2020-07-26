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
    
    func downloaderDidSetDestinationName(_ destinationName: String?, temporaryDirection: String?)
    
    func downloaderDidReceiveExpectedContentLength(_ expectedContentLength: __int64_t)
    
    func downloaderDidReceiveData(ofLength length: __uint64_t)
    
    func downloaderDidFail(withError error: NSError)

}
