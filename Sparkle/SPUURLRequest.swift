//
//  SPUURLRequest.swift
//  Sparkle
//
//  Created by Federico Ciardi on 26/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation
import AppKit

@objcMembers
class SPUURLRequest: NSObject {
    static let URLKey = "SPUURLRequestURL"
    static let CachePolicyKey = "SPUURLRequestCachePolicy"
    static let TimeoutIntervalKey = "SPUURLRequestTimeoutInterval"
    static let HttpHeaderFieldsKey = "SPUURLRequestHttpHeaderFields"
    static let NetworkServiceTypeKey = "SPUURLRequestNetworkServiceType"
    
    private(set) var url: URL
    private(set) var cachePolicy: URLRequest.CachePolicy
    private(set) var timeoutInterval: TimeInterval
    private(set) var httpHeaderFields: [String: String]?
    private(set) var networkServiceType: URLRequest.NetworkServiceType
    var request: URLRequest {
        var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        if httpHeaderFields != nil {
            request.allHTTPHeaderFields = httpHeaderFields
        }
        request.networkServiceType = networkServiceType
        return request
    }
    
    required init(withURL url: URL, cachePolicy: URLRequest.CachePolicy, timeoutInterval: TimeInterval, httpHeaderFields: [String: String], networkServiceType: URLRequest.NetworkServiceType) {
        self.url = url
        self.cachePolicy = cachePolicy
        self.timeoutInterval = timeoutInterval
        self.httpHeaderFields = httpHeaderFields
        self.networkServiceType = networkServiceType
        super.init()
    }
    
    class func URLRequestWithRequest(_ request: URLRequest) -> Self? {
        guard let url = request.url, let httpHeaderFields = request.allHTTPHeaderFields else { return nil }
        return self.init(withURL: url, cachePolicy: request.cachePolicy, timeoutInterval: request.timeoutInterval, httpHeaderFields: httpHeaderFields, networkServiceType: request.networkServiceType)
    }
    
    required convenience init?(coder: NSCoder) {
        guard let url = coder.decodeObject(forKey: SPUURLRequest.URLKey) as? URL,
              let cachePolicy = coder.decodeObject(forKey: SPUURLRequest.CachePolicyKey) as? URLRequest.CachePolicy,
              let timeoutInterval = coder.decodeObject(forKey: SPUURLRequest.TimeoutIntervalKey) as? TimeInterval,
              let httpHeaderFields = coder.decodeObject(forKey: SPUURLRequest.HttpHeaderFieldsKey) as? [String: String],
              let networkServiceType = coder.decodeObject(forKey: SPUURLRequest.NetworkServiceTypeKey) as? URLRequest.NetworkServiceType
        else { return nil }
        
        self.init(withURL: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval, httpHeaderFields: httpHeaderFields, networkServiceType: networkServiceType)
    }
}

extension SPUURLRequest: NSSecureCoding {
    static var supportsSecureCoding: Bool {
        return true
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(url, forKey: SPUURLRequest.URLKey)
        coder.encode(cachePolicy.rawValue, forKey: SPUURLRequest.CachePolicyKey)
        coder.encode(timeoutInterval, forKey: SPUURLRequest.TimeoutIntervalKey)
        coder.encode(networkServiceType.rawValue, forKey: SPUURLRequest.NetworkServiceTypeKey)
        
        if httpHeaderFields != nil {
            coder.encode(httpHeaderFields, forKey: SPUURLRequest.HttpHeaderFieldsKey)
        }
    }
}

