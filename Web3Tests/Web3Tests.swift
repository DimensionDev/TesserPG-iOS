//
//  Web3Tests.swift
//  Web3Tests
//
//  Created by Cirno MainasuK on 2019-11-13.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import XCTest
import Web3

class Web3Tests: XCTestCase {

    let web3 = Web3(rpcURL: "https://ropsten.infura.io/v3/823d2b1356e24d7fbd3b1ae954c6db19")

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSmoke() {

    }

    func testClientVersion() {
        let clientVersionExpectation = expectation(description: "clientVersionExpectation")

        firstly {
            web3.clientVersion()
        }.done { version in
            print(version)
            clientVersionExpectation.fulfill()
        }.catch { error in
            print("Error")
        }

        wait(for: [clientVersionExpectation], timeout: 10.0)
    }

    func testNetVersion() {
        let netVersionExpectation = expectation(description: "netVersionExpectation")

        firstly {
            web3.net.version()
        }.done { version in
            print(version)
            netVersionExpectation.fulfill()
        }.catch { error in
            print("Error")
        }

        wait(for: [netVersionExpectation], timeout: 10.0)
    }

    func testPeerCount() {
        let peerCountExpectation = expectation(description: "peerCountExpectation")

        firstly {
            web3.net.peerCount()
        }.done { ethereumQuantity in
            print(ethereumQuantity.quantity)
            peerCountExpectation.fulfill()
        }.catch { error in
            print("Error")
        }

        wait(for: [peerCountExpectation], timeout: 10.0)
    }

    func testBalance() {
        // https://ropsten.etherscan.io/address/0x464B0B37db1eE1b5Fbe27300aCFBf172fD5E4F53

        let address = try? EthereumAddress(hex: "0x464B0B37db1eE1b5Fbe27300aCFBf172fD5E4F53", eip55: false)
        XCTAssertNotNil(address)

        let getBalanceExpectation = expectation(description: "getBalance")

        web3.eth.getBalance(address: address!, block: .latest) { response in
            switch response.status {
            case .success(let result):
                print(result.quantity)

                let coin = Decimal(string: String(result.quantity))
                print(coin! / pow(Decimal(10), 18))

                getBalanceExpectation.fulfill()
            case .failure(let error):
                print(error)
            }
        }

        wait(for: [getBalanceExpectation], timeout: 10.0)
    }

}
