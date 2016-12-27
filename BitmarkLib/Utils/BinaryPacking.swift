//
//  BinaryPacking.swift
//  BitmarkLib
//
//  Created by Anh Nguyen on 12/22/16.
//  Copyright © 2016 Bitmark. All rights reserved.
//

import Foundation

class BinaryPacking {
    static func append(toData data: Data, withString string: String?, encoding: String.Encoding = String.Encoding.utf8) -> Data {
        let stringData = string?.data(using: encoding)
        
        return append(toData: data, withData: stringData)
    }
    
    static func append(toData data: Data, withData dataAppend: Data?) -> Data {
        if let dataAppend = dataAppend {
            let lengthBuffer = VarInt.encode(value: dataAppend.count)
            
            return data + lengthBuffer + dataAppend
        }
        else {
            return data
        }
    }
}