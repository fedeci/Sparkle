//
//  SUAppcastItem.swift
//  Sparkle
//
//  Created by Federico Ciardi on 29/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

enum SUAppcastItemError: Error {
    case missingAttributeVersion(String)
    case missingEnclosure(String)
    case missingEnclosureURL(String)
    case invalidAttributeInstallationType(String)
}

private let SUAppcastItemDeltaUpdatesKey = "deltaUpdates"
private let SUAppcastItemDisplayVersionStringKey = "displayVersionString"
private let SUAppcastItemSignaturesKey = "signatures"
private let SUAppcastItemFileURLKey = "fileURL"
private let SUAppcastItemInfoURLKey = "infoURL"
private let SUAppcastItemContentLengthKey = "contentLength"
private let SUAppcastItemDescriptionKey = "itemDescription"
private let SUAppcastItemMaximumSystemVersionKey = "maximumSystemVersion"
private let SUAppcastItemMinimumSystemVersionKey = "minimumSystemVersion"
private let SUAppcastItemReleaseNotesURLKey = "releaseNotesURL"
private let SUAppcastItemTitleKey = "title"
private let SUAppcastItemVersionStringKey = "versionString"
private let SUAppcastItemPropertiesKey = "propertiesDictionary"
private let SUAppcastItemInstallationTypeKey = "SUAppcastItemInstallationType"

@objcMembers
class SUAppcastItem: NSObject {
    private(set) var title: String?
    private(set) var dateString: String?
    private(set) var itemDescription: String?
    private(set) var releaseNotesURL: URL?
    private(set) var signatures: SUSignatures?
    private(set) var minimumSystemVersion: String?
    private(set) var maximumSystemVersion: String?
    private(set) var fileURL: URL?
    private(set) var contentLength: UInt64?
    private(set) var versionString: String?
    private(set) var osString: String?
    private(set) var displayVersionString: String?
    private(set) var deltaUpdates: [AnyHashable: Any]?
    private(set) var infoURL: URL?
    private(set) var installationType: String?
    // Returns the dictionary provided in initWithDictionary; this might be useful later for extensions.
    private(set) var propertiesDictionary: [AnyHashable: Any]?
    
    var isDeltaUpdate: Bool {
        guard let rssElementEnclosure = propertiesDictionary?[SURSSElementEnclosure] as? [AnyHashable: Any] else { return false }
        return rssElementEnclosure[SUAppcastAttributeDeltaFrom] != nil
    }

    var isCriticalUpdate: Bool {
        guard let appcastElementTags = propertiesDictionary?[SUAppcastElementTags] as? [AnyHashable] else { return false }
        return appcastElementTags.contains(SUAppcastElementCriticalUpdate)
    }

    var isMacOsUpdate: Bool {
        return osString == nil || osString == SUAppcastAttributeValueMacOS
    }

    var isInformationOnlyUpdate: Bool {
        return infoURL != nil && fileURL == nil
    }

    // Initializes with data from a dictionary provided by the RSS class.
    convenience init(dictionary dict: [AnyHashable: Any]) throws {
        try self.init(dictionary: dict, relativeTo: nil)
    }
    
    init(dictionary dict: [AnyHashable: Any], relativeTo appcastURL: URL?) throws {
        super.init()
        let enclosure = dict[SURSSElementEnclosure] as? [AnyHashable: Any]
        
        // Try to find a version string.
        // Finding the new version number from the RSS feed is a little bit hacky. There are two ways:
        // 1. A "sparkle:version" attribute on the enclosure tag, an extension from the RSS spec.
        // 2. If there isn't a version attribute, Sparkle will parse the path in the enclosure, expecting
        //    that it will look like this: http://something.com/YourApp_0.5.zip. It'll read whatever's between the last
        //    underscore and the last period as the version number. So name your packages like this: APPNAME_VERSION.extension.
        //    The big caveat with this is that you can't have underscores in your version strings, as that'll confuse Sparkle.
        //    Feel free to change the separator string to a hyphen or something more suited to your needs if you like.
        var newVersion: String? = enclosure?[SUAppcastAttributeVersion] as? String
        if newVersion == nil {
            newVersion = dict[SUAppcastAttributeVersion] as? String // Get version from the item, in case it's a download-less item (i.e. paid upgrade).
        }
        
        if newVersion == nil { // no sparkle:version attribute anywhere?
            SULog(.error, "warning: <\(SURSSElementEnclosure)> for URL '\(String(describing: enclosure?[SURSSAttributeURL]))' is missing \(SUAppcastAttributeVersion) attribute. Version comparison may be unreliable. Please always specify \(SUAppcastAttributeVersion)")
            
            // Separate the url by underscores and take the last component, as that'll be closest to the end,
            // then we remove the extension. Hopefully, this will be the version.
            if let fileComponents = (enclosure?[SURSSAttributeURL] as? String)?.components(separatedBy: "_") {
                if fileComponents.count > 1 {
                    newVersion = URL(fileURLWithPath: fileComponents.last ?? "").deletingPathExtension().absoluteString
                }
            }
        }
        
        guard newVersion != nil else {
            throw SUAppcastItemError.missingAttributeVersion("Feed item lacks \(SUAppcastAttributeVersion) attribute, and version couldn't be deduced from file name (would have used last component of a file name like AppName_1.3.4.zip)")
        }
        
        propertiesDictionary = dict
        title = dict[SURSSElementTitle] as? String
        dateString = dict[SURSSElementPubDate] as? String
        itemDescription = dict[SURSSElementDescription] as? String
        
        let theInfoURL = dict[SURSSElementLink]
        if !(theInfoURL is String) {
            SULog(.error, "\(NSStringFromClass(SUAppcastItem.self))-\(NSStringFromSelector(#function)) Info URL is not of valid type.")
        } else {
            if let theInfoURL = theInfoURL as? String {
                infoURL = URL(string: theInfoURL as String, relativeTo: appcastURL)
            }
        }
        
        // Need an info URL or an enclosure URL. Former to show "More Info"
        // page, latter to download & install:
        guard enclosure != nil && theInfoURL != nil else {
            throw SUAppcastItemError.missingEnclosure("No enclosure in feed item")
        }
        
        let enclosureURLString: String? = enclosure?[SURSSAttributeURL] as? String
        guard enclosureURLString != nil && theInfoURL != nil else {
            throw SUAppcastItemError.missingEnclosureURL("Feed item's enclosure lacks URL")
        }
        
        if enclosureURLString != nil {
            var contentLength: Int64 = 0
            if let enclosureLengthString = enclosure?[SURSSAttributeLength] as? String {
                contentLength = Int64(enclosureLengthString) ?? 0
            }
            self.contentLength = contentLength > 0 ? UInt64(contentLength) : 0
        }
        
        if let enclosureURLString = enclosureURLString {
            // Sparkle used to always URL-encode, so for backwards compatibility spaces in URLs must be forgiven.
            let fileURLString = enclosureURLString.replacingOccurrences(of: " ", with: "%20")
            fileURL = URL(string: fileURLString, relativeTo: appcastURL)
        }
        
        if let enclosure = enclosure {
            signatures = SUSignatures(dsa: enclosure[SUAppcastAttributeDSASignature] as? String, ed: enclosure[SUAppcastAttributeEDSignature] as? String)
        }
        
        versionString = newVersion
        minimumSystemVersion = dict[SUAppcastElementMinimumSystemVersion] as? String
        maximumSystemVersion = dict[SUAppcastElementMaximumSystemVersion] as? String
        
        var shortVersionString: String? = enclosure?[SUAppcastAttributeShortVersionString] as? String
        if shortVersionString == nil {
            shortVersionString = dict[SUAppcastAttributeShortVersionString] as? String // fall back on the <item>
        }
        
        if shortVersionString != nil {
            displayVersionString = shortVersionString
        } else {
            displayVersionString = versionString
        }
        
        installationType = enclosure?[SUAppcastAttributeInstallationType] as? String
        
        if installationType == nil {
            installationType = SPUInstallationTypeDefault
        } else if (!SPUValidInstallationType(installationType)) {
            throw SUAppcastItemError.invalidAttributeInstallationType("Feed item's enclosure lacks valid \(SUAppcastAttributeInstallationType) (found \(String(describing: installationType))")
        } else if (installationType == SPUInstallationTypeInteractivePackage) {
            SULog(.default, "warning: '\(SPUInstallationTypeInteractivePackage)' for \(SUAppcastAttributeInstallationType) is deprecated. Use '\(SPUInstallationTypeGuidedPackage)' instead.")
        }
        
        // Find the appropriate release notes URL.
        if let releaseNotesString = dict[SUAppcastElementReleaseNotesLink] as? String {
            let url = URL(string: releaseNotesString, relativeTo: appcastURL)
            if url?.isFileURL == true {
                SULog(.error, "Release notes with file:// URLs are not supported")
            } else {
                releaseNotesURL = url
            }
        } else if let itemDescription = itemDescription, itemDescription.hasPrefix("http://") || itemDescription.hasPrefix("https://") {
            // if the description starts with http:// or https:// use that.
            releaseNotesURL = URL(string: itemDescription)
        } else {
            releaseNotesURL = nil
        }
        
        if let deltaDictionaries = dict[SUAppcastElementDeltas] as? [[AnyHashable: Any]] {
            var deltas: [String: SUAppcastItem] = [:]
            for deltaDictionary in deltaDictionaries {
                guard let deltaFrom = deltaDictionary[SUAppcastAttributeDeltaFrom] as? String else { continue }
                
                var fakeAppCastDict = dict
                fakeAppCastDict.removeValue(forKey: SUAppcastElementDeltas)
                fakeAppCastDict[SURSSElementEnclosure] = deltaDictionary
                let deltaItem = try? SUAppcastItem(dictionary: fakeAppCastDict)
                
                deltas[deltaFrom] = deltaItem
            }
            
            deltaUpdates = deltas
        }
    }
    
    required init?(coder: NSCoder) {
        super.init()
        deltaUpdates = coder.decodeObject(of: [NSDictionary.self, SUAppcastItem.self], forKey: SUAppcastItemDeltaUpdatesKey) as? [AnyHashable: Any]
        displayVersionString = coder.decodeObject(forKey: SUAppcastItemDisplayVersionStringKey) as? String
        signatures = coder.decodeObject(forKey: SUAppcastItemSignaturesKey) as? SUSignatures
        fileURL = coder.decodeObject(forKey: SUAppcastItemFileURLKey) as? URL
        infoURL = coder.decodeObject(forKey: SUAppcastItemInfoURLKey) as? URL

        contentLength = coder.decodeObject(forKey: SUAppcastItemContentLengthKey) as? UInt64

        installationType = coder.decodeObject(forKey: SUAppcastItemInstallationTypeKey) as? String
        guard !SPUValidInstallationType(installationType) else { return nil }

        itemDescription = coder.decodeObject(forKey: SUAppcastItemDescriptionKey) as? String
        maximumSystemVersion = coder.decodeObject(forKey: SUAppcastItemMaximumSystemVersionKey) as? String
        minimumSystemVersion = coder.decodeObject(forKey: SUAppcastItemMinimumSystemVersionKey) as? String
        releaseNotesURL = coder.decodeObject(forKey: SUAppcastItemReleaseNotesURLKey) as? URL
        title = coder.decodeObject(forKey: SUAppcastItemTitleKey) as? String
        versionString = coder.decodeObject(forKey: SUAppcastItemVersionStringKey) as? String
        
        propertiesDictionary = coder.decodeObject(of: [NSDictionary.self, NSString.self, NSDate.self, NSArray.self], forKey: SUAppcastItemPropertiesKey) as? [AnyHashable: Any]
        
    }
}

extension SUAppcastItem: NSSecureCoding {
    static var supportsSecureCoding: Bool {
        return true
    }
    
    func encode(with coder: NSCoder) {
        if let deltaUpdates = deltaUpdates {
            coder.encode(deltaUpdates, forKey: SUAppcastItemDeltaUpdatesKey)
        }
        
        if let displayVersionString = displayVersionString {
            coder.encode(displayVersionString, forKey: SUAppcastItemDisplayVersionStringKey)
        }
        
        if let signatures = signatures {
            coder.encode(signatures, forKey: SUAppcastItemSignaturesKey)
        }
        
        if let fileURL = fileURL {
            coder.encode(fileURL, forKey: SUAppcastItemFileURLKey)
        }

        if let infoURL = infoURL {
            coder.encode(infoURL, forKey: SUAppcastItemInfoURLKey)
        }
        
        if let contentLength = contentLength {
            coder.encode(contentLength, forKey: SUAppcastItemContentLengthKey)
        }

        if let itemDescription = itemDescription {
            coder.encode(itemDescription, forKey: SUAppcastItemDescriptionKey)
        }

        if let maximumSystemVersion = maximumSystemVersion {
            coder.encode(maximumSystemVersion, forKey: SUAppcastItemMaximumSystemVersionKey)
        }

        if let minimumSystemVersion = minimumSystemVersion {
            coder.encode(minimumSystemVersion, forKey: SUAppcastItemMinimumSystemVersionKey)
        }

        if let releaseNotesURL = releaseNotesURL {
            coder.encode(releaseNotesURL, forKey: SUAppcastItemReleaseNotesURLKey)
        }

        if let title = title {
            coder.encode(title, forKey: SUAppcastItemTitleKey)
        }

        if let versionString = versionString {
            coder.encode(versionString, forKey: SUAppcastItemVersionStringKey)
        }

        if let propertiesDictionary = propertiesDictionary {
            coder.encode(propertiesDictionary, forKey: SUAppcastItemPropertiesKey)
        }

        if let installationType = installationType {
            coder.encode(installationType, forKey: SUAppcastItemInstallationTypeKey)
        }
    }
}
