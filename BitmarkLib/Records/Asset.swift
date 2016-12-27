//
//  Asset.swift
//  BitmarkLib
//
//  Created by Anh Nguyen on 12/22/16.
//  Copyright © 2016 Bitmark. All rights reserved.
//

import CryptoSwift

public struct Asset {
    
    private(set) var id: String?
    private(set) var name: String?
    private(set) var fingerprint: String?
    private(set) var metadata: String?
    private(set) var registrant: Address?
    private(set) var signature: Data?
    private(set) var isSigned = false
    
    static let metadataSeparator = "\u{0000}"
    
    // MARK:- Static methods
    
    static func convertString(fromMetadata metadata: [String: String]) -> String {
        let tmp = metadata.reduce([]) { (result, keyvalue) -> [String] in
            var newResult = result
            newResult.append(keyvalue.key)
            newResult.append(keyvalue.value)
            return newResult
        }
        
        return tmp.joined(separator: metadataSeparator)
    }
    
    static func convertMetadata(fromString string: String) throws -> [String: String] {
        let tmp = string.components(separatedBy: metadataSeparator)
        if tmp.count % 2 != 0 {
            throw(BMError("can not parse string to metadata"))
        }
        
        var result = [String: String]()
        let count = tmp.count / 2
        for i in 0..<count {
            let key = tmp[i * 2]
            let value = tmp[i * 2 + 1]
            result[key] = value
        }
        
        return result
    }
    
    static func isValidLength(metadata: String) -> Bool {
        return metadata.characters.count <= Config.AssetConfig.maxMetadata
    }
    
    // MARK:- Internal methods
    
    internal mutating func resetSignState() {
        self.id = nil
        self.isSigned = false
    }
    
    internal func computeAssetId(fingerprint: String?) -> String? {
        guard let fingerprintData = fingerprint?.data(using: .utf8) else {
            return nil
        }
        return fingerprintData.sha3(.sha512).hexEncodedString
    }
    
    internal func packRecord() -> Data {
        var txData: Data
        txData = VarInt.encode(value: Config.AssetConfig.value)
        txData = BinaryPacking.append(toData: txData, withString: self.name)
        txData = BinaryPacking.append(toData: txData, withString: self.fingerprint)
        txData = BinaryPacking.append(toData: txData, withString: self.metadata)
        txData = BinaryPacking.append(toData: txData, withData: self.registrant?.pack())
        
        return txData
    }
    
    // MARK:- Public methods
    
    public mutating func set(metadata: [String: String]) throws {
        let metaDataString = Asset.convertString(fromMetadata: metadata)
        if !Asset.isValidLength(metadata: metaDataString) {
            throw(BMError("meta data's length must be in correct length"))
        }
        self.metadata = metaDataString
        resetSignState()
    }
    
    public mutating func set(fingerPrint: String) throws {
        if !(fingerPrint.characters.count <= Config.AssetConfig.maxFingerprint) {
            throw(BMError("fingerprint's length must be in correct length"))
        }
        self.fingerprint = fingerPrint
        resetSignState()
    }
    
    public mutating func set(name: String) throws {
        if !(name.characters.count <= Config.AssetConfig.maxName) {
            throw(BMError("name's length must be in corrent length"))
        }
        self.name = name
        resetSignState()
    }
    
    public mutating func set(metadata: String) throws {
        let meta = try Asset.convertMetadata(fromString: metadata)
        try set(metadata: meta)
    }
    
    public mutating func sign(withPrivateKey privateKey: PrivateKey) throws {
        if self.name == nil {
            throw(BMError("Asset error: missing name"))
        }
        if self.fingerprint == nil {
            throw(BMError("Asset error: missing fingerprint"))
        }
        self.registrant = privateKey.address
        self.signature = try Ed25519.getSignature(message: self.packRecord(), privateKey: privateKey.privateKey)
        guard let id = computeAssetId(fingerprint: self.fingerprint) else {
            resetSignState()
            return
        }
        self.id = id
        self.isSigned = true
    }
    
    public func getRPCParam() throws -> [String: String] {
        if !self.isSigned {
            throw(BMError("Asset error: need to sign the record before getting RPC message"))
        }
        
        guard let metadata = metadata,
            let fingerprint = fingerprint,
            let name = name,
            let registrant = registrant,
            let signature = signature
        else {
            throw(BMError("Asset error: some field is missing"))
        }
        
        return ["metadata": metadata,
                "name": name,
                "fingerprint": fingerprint,
                "registrant": registrant.string,
                "signature": signature.hexEncodedString]
    }
}