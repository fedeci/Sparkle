//
//  SPUSecureCoding.swift
//  Sparkle
//
//  Created by Federico Ciardi on 01/08/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

private let SURootObjectArchiveKey = "SURootObjectArchive"

func SPUArchiveRootObjectSecurely(_ rootObject: NSSecureCoding) -> Data {
    let data = NSMutableData()
    let keyedArchiver = NSKeyedArchiver(forWritingWith: data)
    keyedArchiver.requiresSecureCoding = true

    keyedArchiver.encode(rootObject, forKey: SURootObjectArchiveKey)
    keyedArchiver.finishEncoding()
    return data as Data
}

func SPUUnarchiveRootObjectSecurely<T>(data: Data, klass: T) -> NSSecureCoding? where T: NSSecureCoding, T: NSObject {
    if #available(OSX 10.13, *) {
        do {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
            unarchiver.requiresSecureCoding = true
            let rootObject = unarchiver.decodeObject(forKey: SURootObjectArchiveKey) as? T
            unarchiver.finishDecoding()
            return rootObject
        } catch let error {
            SULog(.error, "Exception while securely unarchiving object: \(error)")
            return nil
        }
    } else {
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        unarchiver.requiresSecureCoding = true
        let rootObject = unarchiver.decodeObject(of: T.self, forKey: SURootObjectArchiveKey)
        unarchiver.finishDecoding()
        return rootObject
    }
}
