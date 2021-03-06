//
//  Bitmark.swift
//  BitmarkSDK
//
//  Created by Anh Nguyen on 12/23/16.
//  Copyright © 2016 Bitmark. All rights reserved.
//

import Foundation

public struct TransferOffer: Codable {
    let id: String
    let from: String
    let to: String
    let record: CountersignedTransferRequest
    let created_at: Date
    let open: Bool
}

public struct Bitmark: Codable {
    public let id: String
    public let asset_id: String
    public let head_id: String
    public let issuer: String
    public let owner: String
    public let edition: Int?
    public let status: String
    public let offer: TransferOffer?
    public let block_number: Int64
    public let offset: Int64
    public let created_at: Date?
    public let confirmed_at: Date?
}

public extension Bitmark {
    // MARK:- Issue
    public static func newIssuanceParams(assetID: String, quantity: Int) throws -> IssuanceParams {
        if quantity <= 0 {
            throw("Invalid quantity")
        }
        
        
        let baseNonce = UInt64(Date().timeIntervalSince1970) * 1000
        var requests = [IssueRequest]()
        
        // Get asset info
        let bitmarkQuery = try Bitmark.newBitmarkQueryParams()
            .referencedAsset(assetID: assetID)
            .pending(true)
            .limit(size: 1)
        let (bitmarks, _) = try Bitmark.list(params: bitmarkQuery)
        if bitmarks == nil || bitmarks?.count == 0 {
            // Create first one with nonce = 0
            requests.append(createIssueRequest(assetID: assetID, nonce: 0))
        }
        
        // Create the rest with random nonce
        for i in requests.count..<quantity {
            requests.append(createIssueRequest(assetID: assetID, nonce: baseNonce + UInt64(i % 1000)))
        }
        
        let params = IssuanceParams(issuances: requests)
        return params
    }
    
    public static func issue(_ params: IssuanceParams) throws -> [String] {
        let api = API()
        
        let step = 100
        var i = 0
        var shouldContinue = true
        var bitmarkIDs = [String]()
        while shouldContinue {
            var last = i*step + step
            if last > params.issuances.count {
                shouldContinue = false
                last = params.issuances.count
            }
            
            let parts = [IssueRequest](params.issuances[(i*step)..<last])
            let ids = try api.issue(withIssueParams: IssuanceParams(issuances: parts))
            bitmarkIDs += ids
            i += 1
        }
        
        return bitmarkIDs
    }
    
    private static func createIssueRequest(assetID: String, nonce: UInt64) -> IssueRequest {
        var issuanceRequest = IssueRequest()
        issuanceRequest.set(assetId: assetID)
        issuanceRequest.set(nonce: nonce)
        return issuanceRequest
    }
}

extension Bitmark {
    // MARK:- Transfer
    public static func newTransferParams(to owner: AccountNumber) throws -> TransferParams {
        var transferRequest = TransferRequest()
        try transferRequest.set(to: owner)
        return TransferParams(transfer: transferRequest)
    }
    
    public static func transfer(withTransferParams params: TransferParams) throws -> String {
        let api = API()
        return try api.transfer(params)
    }
}

extension Bitmark {
    // MARK:- Transfer offer
    public static func newOfferParams(to owner: AccountNumber, info: [String: Any]?) throws -> OfferParams {
        var transferRequest = TransferRequest()
        transferRequest.set(requireCountersignature: true)
        try transferRequest.set(to: owner)
        let offer = Offer(transfer: transferRequest, extraInfo: info)
        return OfferParams(offer: offer)
    }
    
    public static func offer(withOfferParams params: OfferParams) throws {
        let api = API()
        return try api.offer(params)
    }
    
    public static func newTransferResponseParams(withBitmark bitmark: Bitmark, action: CountersignedTransferAction) throws -> OfferResponseParams {
        guard let offer = bitmark.offer else {
            throw("Cannot find any offer with this bitmark")
        }
        return OfferResponseParams(id: offer.id, action: action, record: offer.record, counterSignature: nil, apiHeader: nil)
    }
    
    public static func respond(withResponseParams responseParam: OfferResponseParams) throws -> String? {
        let api = API()
        return try api.respond(responseParam)
    }
}

extension Bitmark {
    // MARK:- Query
    public static func get(bitmarkID: String, completionHandler: @escaping (Bitmark?, Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                let bitmark = try get(bitmarkID: bitmarkID)
                completionHandler(bitmark, nil)
            } catch let e {
                completionHandler(nil, e)
            }
        }
    }
    
    public static func get(bitmarkID: String) throws -> Bitmark {
        let api = API()
        return try api.get(bitmarkID: bitmarkID)
    }
    
    public static func getWithAsset(bitmarkID: String, completionHandler: @escaping (Bitmark?, Asset?, Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                let (bitmark, asset) = try getWithAsset(bitmarkID: bitmarkID)
                completionHandler(bitmark, asset, nil)
            } catch let e {
                completionHandler(nil, nil, e)
            }
        }
    }
    
    public static func getWithAsset(bitmarkID: String) throws -> (Bitmark, Asset) {
        let api = API()
        return try api.getWithAsset(bitmarkID: bitmarkID)
    }
    
    public static func newBitmarkQueryParams() -> QueryParam {
        return QueryParam(queryItems: [URLQueryItem(name: "pending", value: "true")])
    }
    
    public static func list(params: QueryParam, completionHandler: @escaping ([Bitmark]?, [Asset]?, Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                let (bitmarks, assets) = try list(params: params)
                completionHandler(bitmarks, assets, nil)
            } catch let e {
                completionHandler(nil, nil, e)
            }
        }
    }
    
    public static func list(params: QueryParam) throws -> ([Bitmark]?, [Asset]?) {
        let api = API()
        return try api.listBitmark(builder: params)
    }
}

extension Bitmark: Hashable {
    public var hashValue: Int {
        return self.id.hashValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

extension Bitmark: Equatable {
    public static func == (lhs: Bitmark, rhs: Bitmark) -> Bool {
        return lhs.id == rhs.id
    }
}
