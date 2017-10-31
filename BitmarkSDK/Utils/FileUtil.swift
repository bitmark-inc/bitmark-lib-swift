//
//  FileUtil.swift
//  BitmarkSDK
//
//  Created by Anh Nguyen on 10/11/17.
//  Copyright © 2017 Bitmark. All rights reserved.
//

import Foundation
import CryptoSwift
import TweetNacl

public struct FileUtil {
    public enum FileUtilError: Error {
        case randomFailed
        case openFileFailed
        case sha3ChunkFailed
    }
    
    public struct Fingerprint {
        public static func computeFingerprint(data: Data) -> String {
            let sha3 = SHA3(variant: .sha512)
            let sha3Data = sha3.calculate(for: [UInt8](data))
            return "01" + Data(bytes: sha3Data).hexEncodedString
        }
        
        public static func computeFingerprint(fromFile url: URL) throws -> String {
            let data = try Data(contentsOf: url)
            return computeFingerprint(data: data)
        }
    }
}

fileprivate extension Data {
    fileprivate mutating func append(string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}
