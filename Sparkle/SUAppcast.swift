//
//  SUAppcast.swift
//  Sparkle
//
//  Created by Federico Ciardi on 28/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

extension XMLElement {
    var attributesAsDictionary: [AnyHashable: Any]? {
        var dictionary: [AnyHashable: Any] = [:]
        if let attributeEnum = (attributes as NSArray?)?.objectEnumerator() {
            for case let attribute as XMLNode in attributeEnum {
                guard let attrName = attribute.name else { continue }
                if let attributeStringValue = attribute.stringValue {
                    dictionary[attrName] = attributeStringValue
                }
            }
        }
        return dictionary
    }
}

@objcMembers
class SUAppcast: NSObject {
    var userAgentString: String?
    var httpHeaders: [String: String]?
    var items: [AnyHashable]?
    private var completionBlock: ((NSError?) -> Void)?

    override init() {
        super.init()
    }

    func fetchAppcastFromURL(_ url: URL, inBackground background: Bool, completionBlock block: @escaping (NSError?) -> Void) {
        completionBlock = block

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 30)

        if userAgentString != nil {
            request.setValue(userAgentString, forHTTPHeaderField: "User-Agent")
        }
        request.networkServiceType = background ? .background : .default

        if let httpHeaders = httpHeaders {
            for (key, value) in httpHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        request.setValue("application/rss+xml,*/*;q=0.1", forHTTPHeaderField: "Accept")

        SPUDownloadURL(with: request) { downloadData, error in
            if let downloadData = downloadData {
                do {
                    let appcastItems = try parseAppcastItemsFromXMLData(downloadData.data, relativeTo: downloadData.URL)
                    items = appcastItems
                    completionBlock?(nil)
                    completionBlock = nil
                } catch let error as NSError {
                    let userInfo: [String: Any] = [NSLocalizedDescriptionKey: SULocalizedString("An error occurred while parsing the update feed."), NSUnderlyingErrorKey: error]

                    reportError(NSError(domain: SUSparkleErrorDomain, code: Int(SUError.SUAppcastParseError.rawValue), userInfo: userInfo))
                }
            } else {
                SULog(.error, "Encountered download feed error: \(String(describing: error))")

                var userInfo: [String: Any] = [NSLocalizedDescriptionKey: SULocalizedString("An error occurred while downloading the update feed.")]

                if let error = error {
                    userInfo[NSUnderlyingErrorKey] = error
                }

                reportError(NSError(domain: SUSparkleErrorDomain, code: Int(SUError.SUDownloadError.rawValue), userInfo: userInfo))
            }
        }

    }

    private func parseAppcastItemsFromXMLData(_ appcastData: Data, relativeTo appcastURL: URL?) throws -> [AnyHashable]? {
        guard let appcastURL = appcastURL else { return nil }

        let options: XMLNode.Options = .nodeLoadExternalEntitiesNever
        guard let document = try? XMLDocument(data: appcastData, options: options) else { return nil }

        guard let xmlItems = try? document.nodes(forXPath: "/rss/channel/item") else { return nil }

        let appcastItems: [AnyHashable]?
        var node: XMLNode?

        for xmlItem in xmlItems {
            node = xmlItem
            var nodesDict: [AnyHashable: Any] = [:]
            var dict: [AnyHashable: Any] = [:]

            // First, we'll "index" all the first-level children of this appcast item so we can pick them out by language later.
            if node?.children?.count != nil {
                node = node?.child(at: 0)
                while node != nil {
                    if let name = sparkleNamespacedNameOfNode(node) {
                        var nodes = nodesDict[name] as? [AnyHashable]
                        if nodes == nil {
                            nodes = []
                            nodesDict[name] = nodes
                        }
                        nodes?.append(node)
                    }
                    node = node?.nextSibling
                }
            }

            for case let (key as String, _) in nodesDict {
                node = bestNodeInNodes(nodesDict[key] as? [AnyHashable])
                if key == SURSSElementEnclosure {
                    // enclosure is flattened as a separate dictionary for some reason
                    let encDict = attributesOfNode(node as? XMLElement)
                    dict[key] = encDict
                } else if key == SURSSElementPubDate {
                    // We don't want to parse and create a NSDate instance -
                    // that's a risk we can avoid. We don't use the date anywhere other
                    // than it being accessible from SUAppcastItem
                    if let dateString = node?.stringValue {
                        dict[key] = dateString
                    }
                } else if key == SUAppcastElementDeltas {
                    var deltas: [AnyHashable] = []
                    if let children = node?.children {
                        for child in children {
                            if child.name == SURSSElementEnclosure {
                                deltas.append(attributesOfNode(child as? XMLElement))
                            }
                        }
                        dict[key] = deltas
                    }
                } else if key == SUAppcastElementTags {
                    var tags: [AnyHashable] = []
                    if let children = node?.children {
                        for child in children {
                            if let childName = child.name {
                                tags.append(childName)
                            }
                        }
                        dict[key] = tags
                    }
                } else {
                    // add all other values as strings
                    if let theValue = node?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) {
                        dict[key] = theValue
                    }
                }
            }

            do {
                let anItem = try SUAppcastItem(dictionary: dict, relativeTo: appcastURL)
                appcastItems?.append(anItem)
            } catch let error as NSError {
                SULog(.error, "Sparkle Updater: Failed to parse appcast item: \(error).\nAppcast dictionary was: \(dict)")
                throw NSError(domain: SUSparkleErrorDomain, code: SUError.SUAppcastParseError, userInfo: [NSLocalizedDescriptionKey: error])
            }
        }
    }

    ////
    func copyWithoutDeltaUpdates() -> SUAppcast? {
        guard let items = items else { return nil }
        let other = SUAppcast()
        var nonDeltaItems: [AnyHashable] = []
        for case let item as SUAppcastItem in items {
            if !item.isDeltaUpdate {
                nonDeltaItems.append(item)
            }
        }

        other.items = nonDeltaItems
        return other
    }
    ////
    private func attributesOfNode(_ node: XMLElement?) -> [String: String] {
        guard let attributeEnum = node?.attributes else { return [:] }
        var dictionary: [String: String] = [:]

        for attribute in attributeEnum {
            guard let attrName = sparkleNamespacedNameOfNode(attribute) else { continue }

            if let attributeStringValue = attribute.stringValue {
                dictionary[attrName] = attributeStringValue
            }
        }
        return dictionary
    }
    ////
    private func sparkleNamespacedNameOfNode(_ node: XMLNode?) -> String? {
        // XML namespace prefix is semantically meaningless, so compare namespace URI
        // NS URI isn't used to fetch anything, and must match exactly, so we look for http:// not https://
        if node?.uri == "http://www.andymatuschak.org/xml-namespaces/sparkle" {
            guard let localName = node?.localName else { return nil }
            return "sparkle:" + localName
        } else {
            return node?.name // Backwards compatibility
        }
    }
    ////
    private func bestNodeInNodes(_ nodes: [AnyHashable]?) -> XMLNode? {
        // We use this method to pick out the localized version of a node when one's available.
        guard let nodes = nodes as? [XMLElement] else { return nil }
        guard !nodes.isEmpty else { return nil }
        guard nodes.count != 1 else { return nodes[0] }

        var languages: [String] = []
        var lang: String = ""

        for node in nodes {
            lang = node.attribute(forName: "xml:lang")?.stringValue ?? ""
            languages.append(lang)
        }
        lang = Bundle.preferredLocalizations(from: languages)[0]
        let contains = languages.contains(lang)
        let index = languages.firstIndex(of: contains ? lang : "") ?? NSNotFound

        guard index != NSNotFound else { return nodes[0] }
        return nodes[index]
    }
    ////
    private func reportError(_ error: NSError) {
        var userInfo = error.userInfo

        if userInfo.isEmpty {
            userInfo = [
                NSLocalizedDescriptionKey: SULocalizedString("An error occurred in retrieving update information. Please try again later."),
                NSLocalizedFailureReasonErrorKey: error.localizedDescription,
                NSUnderlyingErrorKey: error
            ]
        }

        if let failingURL = error.userInfo[NSURLErrorFailingURLErrorKey] {
            userInfo[NSURLErrorFailingURLErrorKey] = failingURL
        }

        completionBlock?(NSError(domain: SUSparkleErrorDomain, code: Int(SUError.SUAppcastError.rawValue), userInfo: userInfo))
        completionBlock = nil
    }
}
