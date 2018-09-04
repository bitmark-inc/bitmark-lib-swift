//
//  BItmarkSDK.swift
//  BitmarkSDK
//
//  Created by Anh Nguyen on 8/24/18.
//  Copyright © 2018 Bitmark. All rights reserved.
//

import Foundation

public struct SDKConfig {
    public let apiToken: String
    public let network: Network
    public let urlSession: URLSession
}

var globalConfig: SDKConfig = SDKConfig(apiToken: "", network: .livenet, urlSession: URLSession.shared)

public func initialize(config: SDKConfig) {
    globalConfig = config
}
