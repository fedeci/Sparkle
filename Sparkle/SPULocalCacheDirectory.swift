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
    // Returns a path to a suitable cache directory to create specifically for Sparkle
    // Intermediate directories to this path may not exist yet
    // This path may depend on the type of running process,
    // such that sandboxed vs non-sandboxed processes could yield different paths
    // The caller should create a subdirectory from the path that is returned here so they don't have files that
    // conflict with other callers. Once that subdirectory name is decided, the caller can remove old items inside it (using removeOldItems:in)
    // and then create a unique temporary directory inside it (using createUniqueDirectory:in)
    //
    // It is important to note this may return a different path whether invoked from a sanboxed vs non-sandboxed process, or from a different user
    // For this reason, this method should not be a part of SUHost because its behavior depends on what kind of process it's being invoked from
    static func cachePath(for bundleIdentifier: String) -> String? {
        let cacheURL = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        assert(cacheURL != nil)

        guard let resultPath = cacheURL?.appendingPathComponent(bundleIdentifier).appendingPathComponent(SPUSparkleBundleIdentifier).path else {
            return nil
        }
        return resultPath
    }

    // Remove old files inside a directory
    // A caller may want to invoke this on a directory they own rather than remove and re-create an entire directory
    // This does nothing if the supplied directory does not exist yet
    static func removeOldItems(in directory: String) {
        var filePathsToRemove: [String] = []
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: directory) {
            if let directoryEnumerator = fileManager.enumerator(atPath: directory) {
                let currentDate = Date()
                for case let filename as String in directoryEnumerator {
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
                for filename in filePathsToRemove {
                    try? fileManager.removeItem(atPath: filename)
                }
            }
        }
    }

    // Create a unique directory inside a parent directory
    // The parent directory doesn't have to exist yet. If it doesn't exist, intermediate directories will be created.
    static func createUniqueDirectory(in directory: String) -> String? {
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
