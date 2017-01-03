//
//  Common.swift
//  BitmarkLib
//
//  Created by Anh Nguyen on 12/16/16.
//  Copyright © 2016 Bitmark. All rights reserved.
//

import Foundation
import BigInt

public class Common {
    static func getKey(byValue value: BigUInt) -> KeyType? {
        
        for keyType in Config.keyTypes {
            if BigUInt(keyType.value) == value {
                return keyType
            }
        }
        
        return nil
    }
    
    static func getNetwork(byAddressValue value: BigUInt) -> Network? {
        
        for network in Config.networks {
            if BigUInt(network.addressValue) == value {
                return network
            }
        }
        
        return nil
    }
    
    static func getMostAppearedValue(nodeResults: [NodeResult], keys: [String]? = nil) -> NodeResult {
        
        let error = nodeResults.map { (nodeResult) -> String? in    // Get error field only
                return nodeResult.error
        }
        .map { (error) -> String in                                 // Convert nil to "nil" for easily hashing
            if error == nil {
                return "nil"
            }
            else {
                return error!
            }
        }
        .mode                                                       // Get most appreared error
        
        if let errorMode = error {
            if errorMode == "nil" {
                // No error, continue with results
                // Filter nil
                let results = nodeResults.filter({ (nodeResult) -> Bool in
                    return nodeResult.result != nil
                })
                    .map { (nodeResult) -> [String: Any] in
                    return nodeResult.result!
                }
                
                // O(n*n)
                var result = [String: Any]()
                if let keys = keys {
                    for key in keys {
                        let data = getMostAppearedValue(dataSet: results, key: key)
                        result[key] = data
                    }
                }
                else {
                    result = getMostAppearedValue(dataSet: results)
                }
                
                return NodeResult(result: result, error: nil)
                
            }
            else {
                // If there is error, return error without result
                return NodeResult(result: nil, error: errorMode)
            }
        }
        
        // There are many difference errors returned, something to be wrong ...
        return NodeResult(result: nil, error: nil)
    }
    
    static func getMostAppearedValue(dataSet: [[String: Any]], key: String) -> Any {
        var valueCount = [String: Int]()
        var finalValueString: String? = nil
        var resultValue: Any? = nil
        
        for item in dataSet {
            let value = item[key]
            let valueString = value.debugDescription
            valueCount[valueString] = (valueCount[valueString] ?? 0) + 1
            
            if let finalValueStringUnwrap = finalValueString,
                (valueCount[valueString] ?? 0) > (valueCount[finalValueStringUnwrap] ?? 0) {
                finalValueString = valueString
                resultValue = value
            }
            else {
                finalValueString = valueString
                resultValue = value
            }
        }
        
        return resultValue!                 // Always not nil because we have two above case assigning value to resultValue
    }
    
    static func getMostAppearedValue(dataSet: [[String: Any]]) -> [String: Any] {
        var valueCount = [String: Int]()
        var finalValueString: String? = nil
        var resultValue: [String: Any]? = nil
        
        for item in dataSet {
            let valueString = item.debugDescription
            valueCount[valueString] = (valueCount[valueString] ?? 0) + 1
            
            if let finalValueStringUnwrap = finalValueString,
                (valueCount[valueString] ?? 0) > (valueCount[finalValueStringUnwrap] ?? 0) {
                finalValueString = valueString
                resultValue = item
            }
            else {
                finalValueString = valueString
                resultValue = item
            }
        }
        
        return resultValue!                 // Always not nil because we have two above case assigning value to resultValue
    }
    
    static func increaseOne(baseLength: Int, data: Data) -> Data {
        var nonce = data.slice(start: baseLength, end: data.count)
        var buffer = [UInt8](data)
        
        var value: UInt8 = 0
        
        for i in baseLength..<buffer.count {
            let j = buffer.count - i - 1 + baseLength
            value = buffer[j]
            
            if value == 0xff {
                buffer[j] = 0x00
            }
            else {
                buffer[j] = value + 1
                return Data(bytes: buffer)
            }
        }
        
        buffer.append(0x01)
        
        return Data(bytes: buffer)
    }
    
    public static func findNonce(base: Data, difficulty: Data) -> Data {
        var nonce = BigUInt("8000000000000000", radix: 16)!
        var combine = base + nonce.serialize()
        let baseLength = base.count
        
        var notFoundYet = true
        var count = 0
        
        while notFoundYet {
            combine = increaseOne(baseLength: baseLength, data: combine)
            let hash = combine.sha3(.sha256)
            let hashBN = BigUInt(hash)
            let difficultyBN = BigUInt(difficulty)
            
            if hashBN < difficultyBN {
                notFoundYet = false
            }
            
            count += 1
            print("trying ... \(count)")
        }
        
        return combine.slice(start: baseLength, end: combine.count)
    }
}
