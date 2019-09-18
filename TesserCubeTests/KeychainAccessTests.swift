//
//  KeychainAccessTests.swift
//  TesserCubeTests
//
//  Created by Cirno MainasuK on 2019-8-6.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import XCTest
import KeychainAccess

class KeychainAccessTests: XCTestCase {

    var keychain: Keychain!

    func testBasic() {
        keychain = Keychain(service: "com.tessercube.test", accessGroup: "TesserCube.Tests")
        try! keychain.removeAll()

        try! keychain.set("Value", key: "Key")
        let value = try? keychain.get("Key")

        XCTAssertEqual(value, "Value")
    }

    func testAuthentication() {
        keychain = Keychain(service: "com.Sujitech.TesserCube.Tests", accessGroup: "7LFDZ96332.com.Sujitech.TesserCube")
        // keychain = Keychain(service: "com.Sujitech.TesserCube.Tests", accessGroup: "7LFDZ96332.com.Sujitech.TesserCube").accessibility(.afterFirstUnlock, authenticationPolicy: .userPresence)
        try! keychain.removeAll()

        try! keychain
            .authenticationPrompt("Authenticate to update your password")
            .set("Value", key: "Key")

        let value = try? keychain
            .authenticationPrompt("Unlock secret key to sign message")
            .get("Key")

        XCTAssertEqual(value, "Value")
    }

}
