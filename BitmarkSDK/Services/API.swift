//
//  API.swift
//  BitmarkSDK
//
//  Created by Anh Nguyen on 10/27/17.
//  Copyright © 2017 Bitmark. All rights reserved.
//

import Foundation

struct APIEndpoint {
    public let network: Network
    private(set) var apiServerURL: URL
    
    public mutating func setEndpoint(api: URL, asset: URL) {
        self.apiServerURL = api
    }
}

extension APIEndpoint {
    public static let livenetEndpoint = APIEndpoint(network: .livenet,
                                                    apiServerURL: URL(string: "https://api.bitmark.com")!)
    
    public static let testnetEndpoint = APIEndpoint(network: .testnet,
                                                    apiServerURL: URL(string: "https://api.test.bitmark.com")!)
    
    internal static func endPointForNetwork(_ network: Network) -> APIEndpoint {
        switch network {
        case .livenet:
            return livenetEndpoint
        case .testnet:
            return testnetEndpoint
        }
    }
}

internal struct API {
    let endpoint: APIEndpoint
    let urlSession = URLSession(configuration: URLSessionConfiguration.default)
    
    init(network: Network) {
        self.init(apiEndpoint: APIEndpoint.endPointForNetwork(network))
    }
    
     init(apiEndpoint: APIEndpoint) {
        endpoint = apiEndpoint
    }
}

internal extension URLRequest {
    internal mutating func signRequest(withAccount account: Account, action: String, resource: String) throws {
        let timestamp = Common.timestamp()
        let parts = [action, resource, account.accountNumber.string, timestamp]
        try signRequest(withAccount: account, parts: parts, timestamp: timestamp)
    }
    
    internal mutating func signRequest(withAccount account: Account, parts: [String], timestamp: String) throws {
        let message = parts.joined(separator: "|")
        print(message)
        
        let signature = try account.authKey.sign(message: message).hexEncodedString
        
        self.addValue(account.accountNumber.string, forHTTPHeaderField: "requester")
        self.addValue(timestamp, forHTTPHeaderField: "timestamp")
        self.addValue(signature, forHTTPHeaderField: "signature")
    }
}

internal extension URLSession {
    
    func synchronousDataTask(with request: URLRequest) throws -> (data: Data?, response: HTTPURLResponse?) {
        
        let semaphore = DispatchSemaphore(value: 0)
        
        var responseData: Data?
        var theResponse: URLResponse?
        var theError: Error?
        
        
        print("========================================================")
        print("Request for url: \(request.url!.absoluteURL)")
        
        
        if let method = request.httpMethod {
            print("Request method: \(method)")
        }

        if let header = request.allHTTPHeaderFields {
            print("Request Header: \(header)")
        }

        if let body = request.httpBody {
            print("Request Body: \(String(data: body, encoding: .ascii)!)")
        }
        
        dataTask(with: request) { (data, response, error) -> Void in
            responseData = data
            theResponse = response
            theError = error
            
            semaphore.signal()
            
            }.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        if let error = theError {
            throw error
        }
        
        if let responseD = responseData {
            print("Resonpose Body: \(String(data: responseD, encoding: .ascii)!)")
        }

        print("========================================================")
        
        return (data: responseData, response: theResponse as! HTTPURLResponse?)
        
    }
    
}
