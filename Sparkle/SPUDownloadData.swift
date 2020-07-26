//
//  SPUDownloadData.swift
//  Sparkle
//
//  Created by Federico Ciardi on 21/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

@objcMembers
class SPUDownloadData: NSObject {
    
    static let DataKey = "SPUDownloadData"
    static let URLKey = "SPUDownloadURL"
    static let TextEncodingKey = "SPUDownloadTextEncoding"
    static let MIMETypeKey = "SPUDownloadMIMEType"
    
    private(set) var data: Data
    
    private(set) var URL: URL
    
    private(set) var textEncodingName: String?
    
    private(set) var MIMEType: String?
    
    init(withData data: Data, URL: URL, textEncodingName: String?, MIMEType: String?) {
        self.data = data
        self.URL = URL
        self.textEncodingName = textEncodingName
        self.MIMEType = MIMEType
        super.init()
    }
    
    required convenience init?(coder: NSCoder) {
        guard let data = coder.decodeObject(forKey: SPUDownloadData.DataKey) as? Data else { return nil }
        guard let URL = coder.decodeObject(forKey: SPUDownloadData.URLKey) as? URL else { return nil }

        let textEncodingName = coder.decodeObject(forKey: SPUDownloadData.TextEncodingKey) as? String
        
        let MIMEType = coder.decodeObject(forKey: SPUDownloadData.MIMETypeKey) as? String
        
        self.init(withData: data, URL: URL, textEncodingName: textEncodingName, MIMEType: MIMEType)
    }
}

extension SPUDownloadData: NSSecureCoding {
    static var supportsSecureCoding: Bool {
        return true
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(data, forKey: SPUDownloadData.DataKey)
        coder.encode(URL, forKey: SPUDownloadData.URLKey)
        
        if textEncodingName != nil {
            coder.encode(textEncodingName, forKey: SPUDownloadData.TextEncodingKey)
        }
        
        if MIMEType != nil {
            coder.encode(MIMEType, forKey: SPUDownloadData.MIMETypeKey)
        }
    }
}
