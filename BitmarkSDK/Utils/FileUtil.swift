//
//  FileUtil.swift
//  BitmarkSDK
//
//  Created by Anh Nguyen on 10/11/17.
//  Copyright © 2017 Bitmark. All rights reserved.
//

import Foundation
import TweetNacl

public struct FileUtil {
    public enum FileUtilError: Error {
        case randomFailed
        case openFileFailed
        case sha3ChunkFailed
    }
    
    public static func computeFingerprint(data: Data) -> String {
        let sha3Data = data.sha3(length: 512)
        return "01" + sha3Data.hexEncodedString
    }
    
    public static func computeFingerprint(url: URL) throws -> String {
        let sha3Data = try url.sha3(length: 512)
        return "01" + sha3Data.hexEncodedString
    }
    
    public static func computeFingerprint(urls: [URL]) throws -> String {
        var hashes = [String](repeating: "", count: urls.count)
        var errs = [Error]()
        let serialQueue = DispatchQueue(label: "com.bitmarksdk.serial")
        let group = DispatchGroup()
        
        for (i, url) in urls.enumerated() {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let sha3Data = try url.sha3(length: 512)
                    serialQueue.sync {
                        hashes[i] = sha3Data.base64EncodedString()
                    }
                } catch (let e) {
                    serialQueue.sync {
                        errs.append(e)
                    }
                }
                group.leave()
            }
        }
        
        group.wait()
        
        if errs.count > 0 {
            throw(errs.first!)
        }
        
        return "02" + hashes.joined()
    }
}
