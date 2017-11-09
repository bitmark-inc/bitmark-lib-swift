//
//  API+Assets.swift
//  BitmarkSDK
//
//  Created by Anh Nguyen on 10/30/17.
//  Copyright © 2017 Bitmark. All rights reserved.
//

import Foundation

internal extension API {
    internal func uploadAsset(data: Data, fileName: String, assetId: String, accessibility: Accessibility, fromAccount account: Account) throws -> Bool {
        var params = ["asset_id": assetId,
                      "accessibility": accessibility.rawValue]
        
        let requestURL = apiServerURL.appendingPathComponent("/v1/assets")
        
        var urlRequest: URLRequest
        
        switch accessibility {
        case .publicAsset:
            print("Uploading with public assets")
            urlRequest = API.multipartRequest(data: data, fileName: fileName, toURL: requestURL, otherParams: params)
        case .privateAsset:
            print("Uploading with private assets")
            let assetEncryption = try AssetEncryption()
            let (encryptedData, sessionData) = try assetEncryption.encrypt(data: data, signWithAccount: account)
            let sessionDataSerialized = try JSONEncoder().encode(sessionData)
            params["session_data"] = String(data: sessionDataSerialized, encoding: .utf8)
            
            urlRequest = API.multipartRequest(data: encryptedData, fileName: fileName, toURL: requestURL, otherParams: params)
        }
        
        try urlRequest.signRequest(withAccount: account, action: "uploadAsset", resource: assetId)
        
        let result = try urlSession.synchronousDataTask(with: urlRequest)
        guard let response = result.response else {
                return false
        }
        
        return 200..<300 ~= response.statusCode
    }

    internal func downloadAsset(bitmarkId: String, completion: ((Data?) -> Void)?) {
        let requestURL = apiServerURL.appendingPathComponent("/v1/bitmarks/" + bitmarkId + "/asset")
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        
        urlSession.dataTask(with: request) { (data, _, error) in
            if let error = error {
                print(error)
            }
            
            completion?(data)
        }.resume()
    }
}

fileprivate extension API {
    fileprivate static func multipartRequest(data: Data, fileName: String, toURL url: URL, otherParams: [String: String]?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = createBody(parameters: otherParams, boundary: boundary, data: data, mimeType: "", filename: fileName)
        
        return request
    }
    
    fileprivate static func createBody(parameters: [String: String]?,
                                   boundary: String,
                                   data: Data,
                                   mimeType: String,
                                   filename: String) -> Data {
        var body = Data()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        
        if let parameters = parameters {
            for (key, value) in parameters {
                body.append(string: boundaryPrefix)
                body.append(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append(string: "\(value)\r\n")
            }
        }
        
        body.append(string: boundaryPrefix)
        body.append(string: "Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.append(string: "Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.append(string: "\r\n")
        body.append(string: "--".appending(boundary.appending("--")))
        
        return body
    }
}

fileprivate extension Data {
    fileprivate mutating func append(string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}
