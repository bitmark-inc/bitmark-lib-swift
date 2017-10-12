//
//  Common.swift
//  BitmarkSDK
//
//  Created by Anh Nguyen on 12/16/16.
//  Copyright © 2016 Bitmark. All rights reserved.
//

import Foundation

public class Common {
    static func getKey(byValue value: UInt64) -> KeyType? {
        
        for keyType in Config.keyTypes {
            if keyType.value == value {
                return keyType
            }
        }
        
        return nil
    }
    
    static func getNetwork(byAddressValue value: UInt64) -> Network? {
        
        for network in Config.networks {
            if network.addressValue == value {
                return network
            }
        }
        
        return nil
    }
    
    public static func randomBytes(length: Int) -> Data? {
        var data = Data(count: length)
        let result = data.withUnsafeMutableBytes {
            return SecRandomCopyBytes(kSecRandomDefault, length, $0)
        }
        
        guard result == errSecSuccess else {
            return nil
        }
        
        return data
    }
}