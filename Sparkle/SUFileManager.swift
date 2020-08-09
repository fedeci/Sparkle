//
//  SUFileManager.swift
//  Sparkle
//
//  Created by Federico Ciardi on 01/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation
import System

private let SUAppleQuarantineIdentifier = "com.apple.quarantine"

/// A class used for performing file operations more suitable than NSFileManager for performing installation work.
/// All operations on this class may be used on thread other than the main thread.
/// This class provides just basic file operations and stays away from including much application-level logic.
@objcMembers
class SUFileManager: NSObject {

    private typealias VolumeID = (NSCopying & NSSecureCoding & NSObjectProtocol)

    private var fileManager: FileManager

    override init() {
        fileManager = FileManager()
        super.init()
    }

    /// Creates a temporary directory on the same volume as a provided URL
    /// - Parameter preferredName: A name that may be used when creating the temporary directory. Note that in the uncothirdStageErrormmon case this name is used, the temporary directory will be created inside the directory pointed by appropriateURL
    /// - Parameter directoryURL: A URL to a directory that resides on the volume that the temporary directory will be created on. In the uncommon case, the temporary directory may be created inside this directory.
    /// - Returns: A URL pointing to the newly created temporary directory, or nil with a populated error object if an error occurs.
    ///
    /// When moving an item from a source to a destination, it is desirable to create a temporary intermediate destination on the same volume as the destination to ensure that the item will be moved, and not copied, from the intermediate point to the final destination. This ensures file atomicity.
    func makeTemporaryDirectory(with preferredName: String, appropriateFor directoryURL: URL) throws -> URL {
        if let tempURL = try? fileManager.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: directoryURL, create: true) {
            return tempURL
        }

        // It is pretty unlikely in my testing we will get here, but just in case we do, we should create a directory inside
        // the directory pointed by directoryURL, using the preferredName
        var desiredURL = directoryURL.appendingPathComponent(preferredName)
        var tagIndex: ULONG = 1
        while itemExists(at: desiredURL) && tagIndex <= 9999 {
            tagIndex += 1
            desiredURL = directoryURL.appendingPathComponent(preferredName.appendingFormat(" (%lu)", tagIndex))
        }

        try makeDirectory(at: desiredURL)
        return desiredURL
    }

    /// Creates a directory at the target URL
    /// - Parameter targetURL: A URL pointing to the directory to create. The item at this URL must not exist, and the parent directory of this URL must already exist.
    /// - Returns: true if the item was created successfully, otherwise false.
    ///
    /// This is an atomic operation.
    func makeDirectory(at targetURL: URL) throws {
        guard !itemExists(at: targetURL) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteFileExistsError, userInfo: [NSLocalizedDescriptionKey: "Failed to create directory because file \(targetURL.lastPathComponent) already exists."])
        }

        let parentURL = targetURL.deletingLastPathComponent()
        var isParentADirectory = false
        guard itemExists(at: parentURL, isDirectory: &isParentADirectory) && isParentADirectory else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: [NSLocalizedDescriptionKey: "Failed to create directory because parent directory \(parentURL.lastPathComponent) does not exist."])
        }

        try fileManager.createDirectory(at: targetURL, withIntermediateDirectories: false, attributes: nil)
    }

    /// Moves an item from a source to a destination
    /// - Parameter sourceURL: A URL pointing to the item to move. The item at this URL must exist.
    /// - Parameter destinationURL: A URL pointing to the destination the item will be moved at. An item must not already exist at this URL.
    /// - Returns: true if the item was moved successfully, otherwise false.
    ///
    /// If sourceURL and destinationURL reside on the same volume, this operation will be an atomic move operation.
    /// Otherwise this will be equivalent to a copy & remove which will be a nonatomic operation.
    func moveItem(at sourceURL: URL, to destinationURL: URL) throws {
        guard itemExists(at: sourceURL) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: [NSLocalizedDescriptionKey: "Source file to move (\(sourceURL.lastPathComponent)) does not exist."])
        }

        let destinationURLParent = destinationURL.deletingLastPathComponent()
        guard itemExists(at: destinationURLParent) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: [NSLocalizedDescriptionKey: "Destination parent directory to move into (\(destinationURLParent.lastPathComponent)) does not exist."])
        }

        guard !itemExists(at: destinationURL) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: [NSLocalizedDescriptionKey: "Destination file to move (\(destinationURLParent.lastPathComponent)) already exists."])
        }

        // If the source and destination are on different volumes, we should not do a move;
        // from my experience a move may fail when moving particular files from
        // one network mount to another one. This is possibly related to the fact that
        // moving a file will try to preserve ownership but copying won't

        // cannot initialize a protocol based Type, so we declare it as nil
        var sourceVolumeID: VolumeID?
        try getVolumeID(&sourceVolumeID, ofItemAt: sourceURL)

        var destinationVolumeID: VolumeID?
        try getVolumeID(&destinationVolumeID, ofItemAt: destinationURL)

        if sourceVolumeID?.isEqual(destinationVolumeID) == false {
            try copyItem(at: sourceURL, to: destinationURL)
            try removeItem(at: sourceURL)
            return
        }
        try fileManager.moveItem(at: sourceURL, to: destinationURL)
    }

    /// Copies an item from a source to a destination
    /// - Parameter sourceURL: A URL pointing to the item to move. The item at this URL must exist.
    /// - Parameter destinationURL: A URL pointing to the destination the item will be moved at. An item must not already exist at this URL.
    /// - Returns: true if the item was copied successfully, otherwise false.
    ///
    /// This is not an atomic operation.
    func copyItem(at sourceURL: URL, to destinationURL: URL) throws {
        guard itemExists(at: sourceURL) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: [NSLocalizedDescriptionKey: "Source file to copy (\(sourceURL.lastPathComponent)) does not exist."])
        }

        guard itemExists(at: destinationURL.deletingLastPathComponent()) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: [NSLocalizedDescriptionKey: "Destination parent directory to copy into (\(destinationURL.deletingLastPathComponent().lastPathComponent)) does not exist."])
        }

        guard !itemExists(at: destinationURL) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteFileExistsError, userInfo: [NSLocalizedDescriptionKey: "Destination file to copy to (\(destinationURL.lastPathComponent)) already exists."])
        }

        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }

    /// Removes an item at a URL
    /// - Parameter targetURL: A URL pointing to the item to remove. The item at this URL must exist.
    /// - Returns: true if the item was removed successfully, otherwise false.
    ///
    /// This is not an atomic operation.
    func removeItem(at targetURL: URL) throws {
        guard itemExists(at: targetURL) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: [NSLocalizedDescriptionKey: "Failed to remove file \(targetURL.lastPathComponent) because it does not exist."])
        }

        try fileManager.removeItem(at: targetURL)
    }

    /// Changes the owner and group IDs of an item at a specified target URL to match another URL
    /// - Parameter targetURL: A URL pointing to the target item whose owner and group IDs to alter. This will be applied recursively if the item is a directory. The item at this URL must exist.
    /// - Parameter matchURL: A URL pointing to the item whose owner and group IDs will be used for changing on the targetURL. The item at this URL must exist.
    /// - Returns: true if the target item's owner and group IDs have changed to match the origin's ones, otherwise false.
    ///
    /// If the owner and group IDs match on the root items of targetURL and matchURL, this method stops and assumes that nothing needs to be done.
    /// Otherwise this method recursively changes the IDs if the target is a directory. If an item in the directory is encountered that is unable to be changed,
    /// then this method stops and returns false.
    ///
    /// This is not an atomic operation.
    func changeOwnerAndGroupOfItem(at targetURL: URL, to matchURL: URL) throws {
        var isTargetADirectory = false
        guard itemExists(at: targetURL, isDirectory: &isTargetADirectory) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: [NSLocalizedDescriptionKey: "Failed to change owner & group IDs because \(targetURL.lastPathComponent) does not exist."])
        }

        guard itemExists(at: matchURL) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: [NSLocalizedDescriptionKey: "Failed to match owner & group IDs because \(matchURL.lastPathComponent) does not exist."])
        }

        let matchFileAttributes = try fileManager.attributesOfItem(atPath: matchURL.path)
        let targetFileAttributes = try fileManager.attributesOfItem(atPath: targetURL.path)

        guard let ownerID = (matchFileAttributes[FileAttributeKey.ownerAccountID] as? NSNumber)?.intValue else {
            // shouldn't be possible to error here, but just in case
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError, userInfo: [NSLocalizedDescriptionKey: "Owner ID could not be read from \(matchURL.lastPathComponent)."])
        }

        guard let groupID = (matchFileAttributes[FileAttributeKey.groupOwnerAccountID] as? NSNumber)?.intValue else {
            // shouldn't be possible to error here, but just in case
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError, userInfo: [NSLocalizedDescriptionKey: "Group ID could not be read from \(matchURL.lastPathComponent)."])
        }

        if let targetOwnerID = (targetFileAttributes[FileAttributeKey.ownerAccountID] as? NSNumber)?.intValue,
           let targetGroupID = (targetFileAttributes[FileAttributeKey.groupOwnerAccountID] as? NSNumber)?.intValue,
           ownerID == targetOwnerID && groupID == targetGroupID {
            // Assume they're the same even if we don't check every file recursively
            // Speeds up the common case
            return
        }

        try changeOwnerAndGroupOfItem(at: targetURL, ownerID: ownerID, groupID: groupID)

        if isTargetADirectory {
            #warning("Maybe an error to handle if fileManger.enumerator returns nil")
            if let directoryEnumerator = fileManager.enumerator(at: targetURL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions(rawValue: 0), errorHandler: nil) {
                for case let url as URL in directoryEnumerator {
                    try changeOwnerAndGroupOfItem(at: url, ownerID: ownerID, groupID: groupID)
                }
            }
        }
    }

    /// Updates the modification and access time of an item at a specified target URL to the current time
    /// - Parameter targetURL: A URL pointing to the target item whose modification and access time to update. The item at this URL must exist.
    /// - Returns: true if the target item's modification and access times have been updated, otherwise false.
    ///
    /// This method updates the modification and access time of an item to the current time, ideal for letting the system know we installed a new file or
    /// application.
    ///
    /// This is not an atomic operation.
    func updateModificationAndAccessTimeOfItem(at targetURL: URL) throws {
        guard itemExists(at: targetURL) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: [NSLocalizedDescriptionKey: "Failed to update modification & access time because \(targetURL.lastPathComponent) does not exist."])
        }

        var path = [Int8](repeating: 0, count: Int(PATH_MAX))
        guard (targetURL.path as NSString).getFileSystemRepresentation(&path, maxLength: MemoryLayout.size(ofValue: path)) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadInvalidFileNameError, userInfo: [NSLocalizedDescriptionKey: "File to update modification & access time (\(targetURL.lastPathComponent)) cannot be represented as a valid file name."])
        }

        let fileDescriptor = open(path, O_RDONLY | O_SYMLINK)
        guard fileDescriptor != -1 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSLocalizedDescriptionKey: "Failed to open file descriptor to \(targetURL.lastPathComponent)"])
        }

        // Using futimes() because utimes() follows symbolic links
        let updatedTime = futimes(fileDescriptor, nil) == 0
        close(fileDescriptor)
        guard updatedTime else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSLocalizedDescriptionKey: "Failed to create directory because file \(targetURL.lastPathComponent) already exists."])
        }
    }

    /// Updates the access time of an item at a specified root URL to the current time
    /// - Parameter targetURL: A URL pointing to the target item whose access time to update to the current time.
    /// This will be applied recursively if the item is a directory. The item at this URL must exist.
    /// - Returns: true if the target item's access times have been updated, otherwise false.
    ///
    /// This method updates the access time of an item to the current time, ideal for letting the system know not to remove a file or directory when placing it
    /// at a temporary directory.
    ///
    /// This is not an atomic operation.
    func updateAccessTimeOfItem(at targetURL: URL) throws {
        guard itemExists(at: targetURL) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: [NSLocalizedDescriptionKey: "Failed to update modification & access time recursively because \(targetURL.lastPathComponent) does not exist."])
        }

        // We want to update all files with the same exact time
        var currentTime = timeval(tv_sec: 0, tv_usec: 0)
        guard gettimeofday(&currentTime, nil) == 0 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSLocalizedDescriptionKey: "Failed to update modification & access time recursively because gettimeofday failed."])
        }

        let rootURLPath = targetURL.path
        let rootAttributes = try fileManager.attributesOfItem(atPath: rootURLPath)

        // Only recurse if it's actually a directory.  Don't recurse into a
        // root-level symbolic link.
        if let rootType = rootAttributes[FileAttributeKey.type] as? String, rootType == FileAttributeType.typeDirectory.rawValue {
            // The NSDirectoryEnumerator will avoid recursing into any contained
            // symbolic links, so no further type checks are needed.
            #warning("Maybe an error to handle if fileManger.enumerator returns nil")
            if let directoryEnumerator = fileManager.enumerator(at: targetURL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions(rawValue: 0), errorHandler: nil) {
                for case let file as URL in directoryEnumerator {
                    try updateItem(at: file, with: currentTime)
                }
            }
        }

        // Set the access time on the container last because the process of setting the access
        // time on children actually causes the access time of the container directory to be
        // updated.
        try updateItem(at: targetURL, with: currentTime)
    }

    // Removes the directory tree rooted at |root| from the file quarantine.
    // The quarantine was introduced on macOS 10.5 and is described at:
    //
    // http://developer.apple.com/releasenotes/Carbon/RN-LaunchServices/index.html#apple_ref/doc/uid/TP40001369-DontLinkElementID_2
    //
    // If |root| is not a directory, then it alone is removed from the quarantine.
    // Symbolic links, including |root| if it is a symbolic link, will not be
    // traversed.

    // Ordinarily, the quarantine is managed by calling LSSetItemAttribute
    // to set the kLSItemQuarantineProperties attribute to a dictionary specifying
    // the quarantine properties to be applied.  However, it does not appear to be
    // possible to remove an item from the quarantine directly through any public
    // Launch Services calls.  Instead, this method takes advantage of the fact
    // that the quarantine is implemented in part by setting an extended attribute,
    // "com.apple.quarantine", on affected files.  Removing this attribute is
    // sufficient to remove files from the quarantine.

    // This works by removing the quarantine extended attribute for every file we come across.
    // We used to have code similar to the method below that used -[NSURL getResourceValue:forKey:error:] and -[NSURL setResourceValue:forKey:error:]
    // However, those methods *really suck* - you can't rely on the return value from getting the resource value and if you set the resource value
    // when the key isn't present, errors are spewed out to the console
    /// Releases Apple's quarantine extended attribute from the item at the specified root URL
    /// - Parameter rootURL: A URL pointing to the item to release from Apple's quarantine. This will be applied recursively if the item is a directory. The item at this URL must exist.
    /// - Returns: true if all the items at the target could be released from quarantine, otherwise false if any items couldn't.
    ///
    /// This method removes quarantine attributes from an item, ideally an application, so that when the user launches a new application themselves, they
    /// don't have to witness the system dialog alerting them that they downloaded an application from the internet and asking if they want to continue.
    /// Note that this may not exactly mimic the system behavior when a user opens an application for the first time (i.e, the xattr isn't deleted),
    /// but this should be sufficient enough for our purposes.
    ///
    /// This method may return false even if some items do get released from quarantine if the target URL is pointing to a directory.
    /// Thus if an item cannot be released from quarantine, this method still continues on to the next enumerated item.
    ///
    /// This is not an atomic operation.
    func releaseItemFromQuarantine(at rootURL: URL) throws {
        let removeXAttrOptions = XATTR_NOFOLLOW

        // First remove quarantine on the root item
        let rootURLPath = rootURL.path
        if getXAttr(name: SUAppleQuarantineIdentifier, from: rootURLPath, options: removeXAttrOptions) >= 0 {
            let removedRootQuarantine = removeXAttr(attr: SUAppleQuarantineIdentifier, fromFile: rootURLPath, options: removeXAttrOptions) == 0
            guard removedRootQuarantine else {
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSLocalizedDescriptionKey: "Failed to remove file quarantine on \(rootURL.lastPathComponent)."])
            }
        }

        // Only recurse if it's actually a directory.  Don't recurse into a root-level symbolic link.
        // Even if we fail removing the quarantine from the root item or any single item in the directory, we will continue trying to remove the quarantine.
        // This is because often it may not be a fatal error from the caller to not remove the quarantine of an item
        let rootAttributes = try? fileManager.attributesOfItem(atPath: rootURLPath)
        let rootType = rootAttributes?[FileAttributeKey.type] as? String

        if rootType == FileAttributeType.typeDirectory.rawValue {
            // The FileManager.DirectoryEnumerator will avoid recursing into any contained
            // symbolic links, so no further type checks are needed.

            #warning("Maybe an error to handle if fileManger.enumerator returns nil")
            if let directoryEnumerator = fileManager.enumerator(at: rootURL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions(rawValue: 0), errorHandler: nil) {
                for case let fileURL as URL in directoryEnumerator {
                    if getXAttr(name: SUAppleQuarantineIdentifier, from: fileURL.path, options: removeXAttrOptions) >= 0 {
                        let removedQuarantine = removeXAttr(attr: SUAppleQuarantineIdentifier, fromFile: fileURL.path, options: removeXAttrOptions) == 0
                        guard removedQuarantine else {
                            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSLocalizedDescriptionKey: "Failed to remove file quarantine on \(fileURL.lastPathComponent)."])
                        }
                    }
                }
            }
        }
    }

    // MARK: - Private methods
    private func itemExists(at fileURL: URL) -> Bool {
        let path = fileURL.path
        return (try? fileManager.attributesOfItem(atPath: path)) != nil
    }

    private func itemExists(at fileURL: URL, isDirectory: inout Bool) -> Bool {
        let path = fileURL.path
        guard let attributes = try? fileManager.attributesOfItem(atPath: path) else { return false }

        isDirectory = attributes[FileAttributeKey.type] as? FileAttributeType == .typeDirectory

        return true
    }

    // Wrapper around getxattr()
    private func getXAttr(name: UnsafePointer<Int8>, from file: String, options: Int32) -> Int {
        var path = [Int8](repeating: 0, count: Int(PATH_MAX))
        guard (file as NSString).getFileSystemRepresentation(&path, maxLength: MemoryLayout.size(ofValue: path)) else {
            errno = 0
            return -1
        }

        return getxattr(&path, name, nil, 0, 0, options)
    }

    // Wrapper around removexattr()
    private func removeXAttr(attr: UnsafePointer<Int8>, fromFile file: String, options: Int32) -> Int32 {
        var path = [Int8](repeating: 0, count: Int(PATH_MAX))
        guard (file as NSString).getFileSystemRepresentation(&path, maxLength: MemoryLayout.size(ofValue: path)) else {
            errno = 0
            return -1
        }

        return removexattr(&path, attr, options)
    }

    private func changeOwnerAndGroupOfItem(at targetURL: URL, ownerID: Int, groupID: Int) throws {
        var path = [Int8](repeating: 0, count: Int(PATH_MAX))
        guard (targetURL.path as NSString).getFileSystemRepresentation(&path, maxLength: MemoryLayout.size(ofValue: path)) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadInvalidFileNameError, userInfo: [NSLocalizedDescriptionKey: "File to change owner & group (\(targetURL.lastPathComponent)) cannot be represented as a valid file name."])
        }

        let fileDescriptor = open(path, O_RDONLY | O_SYMLINK)
        guard fileDescriptor != -1 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSLocalizedDescriptionKey: "Failed to open file descriptor to \(targetURL.lastPathComponent)"])
        }

        // We use fchown instead of chown because the latter can follow symbolic links
        let success = fchown(fileDescriptor, UInt32(ownerID), UInt32(groupID)) == 0
        close(fileDescriptor)

        guard success else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSLocalizedDescriptionKey: "Failed to change owner & group for \(targetURL.lastPathComponent) with owner ID \(ownerID) and group ID \(groupID)."])
        }
    }

    private func updateItem(at targetURL: URL, with accessTime: timeval) throws {
        var path = [Int8](repeating: 0, count: Int(PATH_MAX))

        // NOTE: At least on Mojave 10.14.1, running on an APFS filesystem, the act of asking
        // for a path's file system representation causes the access time of the containing folder
        // to be updated. Callers should take care when attempting to set a recursive directory's
        // access time to ensure that the inner-most items get set first, so that the implicitly
        // updated access times are replaced after this side-effect occurs.
        guard (targetURL.path as NSString).getFileSystemRepresentation(&path, maxLength: MemoryLayout.size(ofValue: path)) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadInvalidFileNameError, userInfo: [NSLocalizedDescriptionKey: "File to update modification & access time (\(targetURL.lastPathComponent)) cannot be represented as a valid file name."])
        }

        let fileDescriptor = open(path, O_RDONLY | O_SYMLINK)
        guard fileDescriptor != -1 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSLocalizedDescriptionKey: "Failed to open file descriptor to \(targetURL.lastPathComponent)"])
        }

        // create a blank instance of statfs
        let statInfoPtr = UnsafeMutablePointer<stat>.allocate(capacity: MemoryLayout<stat>.size)
        var statInfo = statInfoPtr.move()

        guard fstat(fileDescriptor, &statInfo) == 0 else {
            close(fileDescriptor)
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSLocalizedDescriptionKey: "Failed to stat file descriptor to \(targetURL.lastPathComponent)"])
        }

        // Preserve the modification time
        var modTime = timeval()
        timespecToTimeval(timeval: &modTime, timespec: statInfo.st_mtimespec)

        let timeInputs = [accessTime, modTime]
        // Using futimes() because utimes() follows symbolic links
        let updatedTime = futimes(fileDescriptor, timeInputs) == 0

        close(fileDescriptor)

        guard !updatedTime else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSLocalizedDescriptionKey: "Failed to update modification & access time for \(targetURL.lastPathComponent)"])
        }
    }

    /// Retrieves the volume ID that a particular url resides on
    /// The url must point to a file that exists
    /// There is no cocoa equivalent for obtaining the volume ID
    ///
    /// If the function does not throw it is ok to assume that `volumeID` is not optional.
    private func getVolumeID(_ volumeID: inout VolumeID?, ofItemAt url: URL) throws {
        guard itemExists(at: url) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: [NSLocalizedDescriptionKey: "Cannot get volume identifier of \(url.lastPathComponent) because it does not exist."])
        }
        let values = try url.resourceValues(forKeys: [.volumeIdentifierKey])

        guard let volumeIdentifier = values.volumeIdentifier else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSURLErrorResourceUnavailable, userInfo: [NSLocalizedDescriptionKey: "Cannot get volume identifier of \(url.lastPathComponent) because the resource is not available."])
        }
        volumeID = volumeIdentifier
    }

    private func timespecToTimeval(timeval: inout timeval, timespec: timespec) {
        timeval.tv_sec = timespec.tv_sec
        timeval.tv_usec = Int32(timespec.tv_nsec / 1000)
    }
}
