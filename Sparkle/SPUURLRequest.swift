//
//  SPUURLRequest.swift
//  Sparkle
//
//  Created by Federico Ciardi on 26/07/2020.
//  Copyright © 2020 Sparkle Project. All rights reserved.
//

import Foundation

private let SPUURLRequestURLKey = "SPUURLRequestURL"
private let SPUURLRequestCachePolicyKey = "SPUURLRequestCachePolicy"
private let SPUURLRequestTimeoutIntervalKey = "SPUURLRequestTimeoutInterval"
private let SPUURLRequestHttpHeaderFieldsKey = "SPUURLRequestHttpHeaderFields"
private let SPUURLRequestNetworkServiceTypeKey = "SPUURLRequestNetworkServiceType"

// A class that wraps NSURLRequest and implements NSSecureCoding
// This class exists because NSURLRequest did not support NSSecureCoding in macOS 10.8
// I have not verified if NSURLRequest in 10.9 implements NSSecureCoding or not
@objcMembers
class SPUURLRequest: NSObject {
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

    required init(url: URL, cachePolicy: URLRequest.CachePolicy, timeoutInterval: TimeInterval, httpHeaderFields: [String: String], networkServiceType: URLRequest.NetworkServiceType) {
        self.url = url
        self.cachePolicy = cachePolicy
        self.timeoutInterval = timeoutInterval
        self.httpHeaderFields = httpHeaderFields
        self.networkServiceType = networkServiceType
        super.init()
    }

    // Creates a new URL request
    // Only these properties are currently tracked:
    // * URL
    // * Cache policy
    // * Timeout interval
    // * HTTP header fields
    // * networkServiceType
    class func URLRequestWithRequest(_ request: URLRequest) -> Self? {
        guard let url = request.url, let httpHeaderFields = request.allHTTPHeaderFields else { return nil }
        return self.init(url: url, cachePolicy: request.cachePolicy, timeoutInterval: request.timeoutInterval, httpHeaderFields: httpHeaderFields, networkServiceType: request.networkServiceType)
    }

    required convenience init?(coder: NSCoder) {
        guard let url = coder.decodeObject(forKey: SPUURLRequestURLKey) as? URL,
              let cachePolicy = coder.decodeObject(forKey: SPUURLRequestCachePolicyKey) as? URLRequest.CachePolicy,
              let timeoutInterval = coder.decodeObject(forKey: SPUURLRequestTimeoutIntervalKey) as? TimeInterval,
              let httpHeaderFields = coder.decodeObject(forKey: SPUURLRequestHttpHeaderFieldsKey) as? [String: String],
              let networkServiceType = coder.decodeObject(forKey: SPUURLRequestNetworkServiceTypeKey) as? URLRequest.NetworkServiceType
        else { return nil }

        self.init(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval, httpHeaderFields: httpHeaderFields, networkServiceType: networkServiceType)
    }
}

extension SPUURLRequest: NSSecureCoding {
    static var supportsSecureCoding: Bool {
        return true
    }

    func encode(with coder: NSCoder) {
        coder.encode(url, forKey: SPUURLRequestURLKey)
        coder.encode(cachePolicy.rawValue, forKey: SPUURLRequestCachePolicyKey)
        coder.encode(timeoutInterval, forKey: SPUURLRequestTimeoutIntervalKey)
        coder.encode(networkServiceType.rawValue, forKey: SPUURLRequestNetworkServiceTypeKey)

        if httpHeaderFields != nil {
            coder.encode(httpHeaderFields, forKey: SPUURLRequestHttpHeaderFieldsKey)
        }
    }
}
