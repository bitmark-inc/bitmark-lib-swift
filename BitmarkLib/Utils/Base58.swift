//
//  Base58.swift
//  BitmarkLib
//
//  Created by Anh Nguyen on 12/16/16.
//  Copyright © 2016 Bitmark. All rights reserved.
//

import Foundation
import BigInt

class Base58 {
    
    static let BTCAlphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    
    
    static let bigRadix = BigUInt(58)
    static let bigZero = BigUInt(0)
    
    public static func decode(_ b: String) -> Data? {
        return decodeAlphabet(b, alphabet: BTCAlphabet)
    }
    
    public static func encode(_ b: Data) -> String {
        return encodeAlphabet(b, alphabet: BTCAlphabet)
    }
    
    static func decodeAlphabet(_ b: String, alphabet: String) -> Data? {
        var answer = BigUInt(0)
        var j = BigUInt(1)
        
        for ch in Array(b.characters.reversed()) {
            // Find the index of the letter ch in the alphabet.
            if let charRange = alphabet.range(of: String(ch)) {
                let letterIndex = alphabet.characters.distance(from: alphabet.startIndex, to: charRange.lowerBound)
                let idx = BigUInt(letterIndex)
                var tmp1 = BigUInt(0)
                
                tmp1 = j * idx
                
                answer += tmp1
                
                j *= bigRadix
            } else {
                
                return nil
            }
        }
        
        
        /// Remove leading 1's
        // Find the first character that isn't 1
        let bArr = Array(b.characters)
        let zChar = Array(alphabet.characters).first
        var nz = 0
        
        for _ in 0 ..< b.characters.count {
            if bArr[nz] != zChar { break }
            nz += 1
        }
        
        let tmpval = [UInt8](answer.serialize())
        var val = [UInt8](repeating: 0, count: nz)
        val += tmpval
        return Data(bytes: val)
        
    }
    
    
    static func encodeAlphabet(_ byteSlice: Data, alphabet: String) -> String {
        var bytesAsIntBig = BigUInt(byteSlice)
        let byteAlphabet = [UInt8](alphabet.utf8)
        
        var answer = [UInt8]()//(count: byteSlice.count*136/100, repeatedValue: 0)
        
        while bytesAsIntBig > bigZero {
            
            let (quotient, modulus) = bytesAsIntBig.divided(by: bigRadix)
            
            bytesAsIntBig = quotient
            
            // Make the String into an array of characters.
            let intModulus = Int(truncatingBitPattern: modulus.toIntMax())
            answer.insert(byteAlphabet[intModulus], at: 0)
        }
        
        // leading zero bytes
        for ch in byteSlice {
            if ch != 0 { break }
            answer.insert(byteAlphabet[0], at: 0)
        }
        
        return String(bytes: answer, encoding: String.Encoding.utf8)!
    }

}
