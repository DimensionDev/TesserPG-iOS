//
//  RedPacketRawPayloadTests.swift
//  Web3Tests
//
//  Created by Cirno MainasuK on 2019-12-20.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import XCTest
import BigInt
import CryptoSwift
import DataCompression

class RedPacketRawPayloadTests: XCTestCase {
    
    var aes: AES!
    
    override func setUp() {
        super.setUp()
        
        // In combined mode, the authentication tag is directly appended to the encrypted message. This is usually what you want.
//        let iv = GCM_IV
//        let key = AES_KEY
//
//        let gcm = GCM(iv: iv, mode: .combined)
//        aes = try! AES(key: key, blockMode: gcm, padding: .noPadding)
        
    }

    func testAES_GCM() {
//        let plaintext = "Plain 1234567890 ABCDEFG"
//
//        let encrypted = try! aes.encrypt(plaintext.bytes)
//        print("hex: " + encrypted.toHexString())
//        print("base64: " + encrypted.toBase64()!)
//
//        let decrypted = try! aes.decrypt(encrypted)
//        print("plaintext: " + String(data: Data(decrypted), encoding: .utf8)!)
//        XCTAssertEqual(plaintext.bytes, decrypted)
    }

}
