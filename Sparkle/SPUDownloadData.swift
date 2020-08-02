//
//  SPUDownloadData.swift
//  Sparkle
//
//  Created by Federico Ciardi on 21/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

private let SPUDownloadDataKey = "SPUDownloadData"
private let SPUDownloadURLKey = "SPUDownloadURL"
private let SPUDownloadTextEncodingKey = "SPUDownloadTextEncoding"
private let SPUDownloadMIMETypeKey = "SPUDownloadMIMEType"

@objcMembers
class SPUDownloadData: NSObject {
    private(set) var data: Data
    private(set) var URL: URL
    private(set) var textEncodingName: String?
    private(set) var MIMEType: String?

    init(data: Data, URL: URL, textEncodingName: String?, MIMEType: String?) {
        self.data = data
        self.URL = URL
        self.textEncodingName = textEncodingName
        self.MIMEType = MIMEType
        super.init()
    }

    required convenience init?(coder: NSCoder) {
        guard let data = coder.decodeObject(forKey: SPUDownloadDataKey) as? Data else { return nil }
        guard let URL = coder.decodeObject(forKey: SPUDownloadURLKey) as? URL else { return nil }

        let textEncodingName = coder.decodeObject(forKey: SPUDownloadTextEncodingKey) as? String

        let MIMEType = coder.decodeObject(forKey: SPUDownloadMIMETypeKey) as? String

        self.init(data: data, URL: URL, textEncodingName: textEncodingName, MIMEType: MIMEType)
    }
}

extension SPUDownloadData: NSSecureCoding {
    static var supportsSecureCoding: Bool {
        return true
    }

    func encode(with coder: NSCoder) {
        coder.encode(data, forKey: SPUDownloadDataKey)
        coder.encode(URL, forKey: SPUDownloadURLKey)

        if textEncodingName != nil {
            coder.encode(textEncodingName, forKey: SPUDownloadTextEncodingKey)
        }

        if MIMEType != nil {
            coder.encode(MIMEType, forKey: SPUDownloadMIMETypeKey)
        }
    }
}
