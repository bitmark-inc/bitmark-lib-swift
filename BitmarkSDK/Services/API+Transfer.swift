//
//  API+Transfer.swift
//  BitmarkSDK
//
//  Created by Anh Nguyen on 10/31/17.
//  Copyright © 2017 Bitmark. All rights reserved.
//

import Foundation

extension API {
    internal func transfer(withData transfer: Transfer) throws -> Bool {
        let json = try JSONSerialization.data(withJSONObject: transfer.getRPCParam(), options: [])
        
        let requestURL = endpoint.apiServerURL.appendingPathComponent("/v1/transfer")
        
        var urlRequest = URLRequest(url: requestURL, cachePolicy: .reloadIgnoringCacheData)
        urlRequest.httpBody = json
        urlRequest.httpMethod = "POST"
        
        let (result, response) = try urlSession.synchronousDataTask(with: urlRequest)
        
        guard let r = result,
            let res = response else {
            return false
        }
        
        return 200..<300 ~= res.statusCode
    }
    
    internal func transfer(withData countersignTransfer: CountersignedTransferRecord) throws -> String {
        let body = ["transfer": countersignTransfer]
        let json = try JSONEncoder().encode(body)
        
        let requestURL = endpoint.apiServerURL.appendingPathComponent("/v1/transfer")
        
        var urlRequest = URLRequest(url: requestURL, cachePolicy: .reloadIgnoringCacheData)
        urlRequest.httpBody = json
        urlRequest.httpMethod = "POST"
        
        let (result, response) = try urlSession.synchronousDataTask(with: urlRequest)
        
        guard let r = result,
            let _ = response else {
                throw("Invalid response from gateway server")
        }
        
        let responseData = try JSONDecoder().decode([[String: String]].self, from: r)
        guard let txid = responseData[0]["txid"] else {
            throw("Invalid response from gateway server")
        }
        
        return txid
    }
    
    internal func submitTransferOffer(withSender sender: Account, offer: TransferOffer, extraInfo: [String: Any]?) throws -> String {
        let requestURL = endpoint.apiServerURL.appendingPathComponent("/v2/transfer_offers")
        
        var params: [String: Any] = ["from": sender.accountNumber.string,
                    "record": try offer.serialize()]
        if let extraInfo = extraInfo {
            params["extra_info"] = extraInfo
        }
        
        var urlRequest = URLRequest(url: requestURL)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        
        let action = "transferOffer"
        let resource = String(data: try JSONEncoder().encode(try offer.serialize()), encoding: .utf8)!
        
        try urlRequest.signRequest(withAccount: sender, action: action, resource: resource)
        
        let (d, res) = try urlSession.synchronousDataTask(with: urlRequest)
        guard let response = res,
            let data = d else {
            throw("Cannot get http response")
        }
        
        if !(200..<300 ~= response.statusCode) {
            throw("Request status" + String(response.statusCode))
        }
        
        let responseData = try JSONDecoder().decode([String: String].self, from: data)
        guard let offerId = responseData[0]["offer_id"] else {
            throw("Invalid response from gateway server")
        }
        
        return offerId
    }
    
    internal func completeTransferOffer(withAccount account: Account, offerId: String, action: String, counterSignature: String) throws -> String {
        let requestURL = endpoint.apiServerURL.appendingPathComponent("/v2/transfer_offers")
        
        let params: [String: Any]  = ["id": offerId,
                                      "reply":
                                        ["action": action,
                                         "countersignature": counterSignature]]
        
        var urlRequest = URLRequest(url: requestURL)
        urlRequest.httpMethod = "PATCH"
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        try urlRequest.signRequest(withAccount: account, action: "transferOffer", resource: "patch")
        
        let (d, res) = try urlSession.synchronousDataTask(with: urlRequest)
        guard let response = res,
            let data = d else {
                throw("Cannot get http response")
        }
        
        if !(200..<300 ~= response.statusCode) {
            throw("Request status" + String(response.statusCode))
        }
        
        let responseData = try JSONDecoder().decode([[String: String]].self, from: data)
        guard let txId = responseData[0]["tx_id"] else {
            throw("Invalid response from gateway server")
        }
        
        return txId
    }
}
