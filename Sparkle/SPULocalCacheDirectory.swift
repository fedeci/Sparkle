//
//  SPULocalCacheDirectory.swift
//  Sparkle
//
//  Created by Federico Ciardi on 27/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

private let OLD_ITEM_DELETION_INTERVAL: TimeInterval = 86400 * 10 // 10 days

@objcMembers
class SPULocalCacheDirectory: NSObject {
    // It is important to note this may return a different path whether invoked from a sanboxed vs non-sandboxed process, or from a different user
    // For this reason, this method should not be a part of SUHost because its behavior depends on what kind of process it's being invoked from
    static func cachePathForBundleIdentifier(_ bundleIdentifier: String) -> String {
        let cacheURL = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        assert(cacheURL != nil)
        
        let resultPath = cacheURL?.appendingPathComponent(bundleIdentifier).appendingPathComponent(SUBundleIdentifier).path
        assert(resultPath != nil)
        
        return resultPath!
    }
    
    static func removeOldItemsInDirectory(_ directory: String) {
        var filePathsToRemove: [String] = []
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: directory) {
            if let directoryEnumerator = fileManager.enumerator(atPath: directory) {
                let currentDate = Date()
                for filename in directoryEnumerator {
                    if let filename = filename as? String {
                        let path = URL(fileURLWithPath: directory).appendingPathComponent(filename).absoluteString
                        if let fileAttributes = try? fileManager.attributesOfItem(atPath: path) {
                            if let lastModificationDate = fileAttributes[FileAttributeKey.modificationDate] as? Date {
                                if currentDate.timeIntervalSince(lastModificationDate) >= OLD_ITEM_DELETION_INTERVAL {
                                    filePathsToRemove.append(URL(fileURLWithPath: directory).appendingPathComponent(filename).absoluteString)
                                }
                            }
                        }
                        directoryEnumerator.skipDescendents()
                    }
                }
                for filename in filePathsToRemove {
                    try? fileManager.removeItem(atPath: filename)
                }
            }
        }
    }
    
    static func createUniqueDirectoryInDirectory(_ directory: String) -> String? {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            SULog(.error, "Failed to create directory with intermediate components at \(directory) with error \(error)")
            return nil
        }
        
        var buffer = [Int8](repeating: 0, count: Int(PATH_MAX))
        let templateString = URL(fileURLWithPath: directory).appendingPathComponent("XXXXXXXXX").absoluteString as NSString
        if templateString.getFileSystemRepresentation(&buffer, maxLength: MemoryLayout.size(ofValue: buffer)) {
            if mkdtemp(&buffer) != nil {
                return NSString(utf8String: &buffer) as String?
            }
        }
        return nil
    }
}
