//
//  Web3Tests.swift
//  Web3Tests
//
//  Created by Cirno MainasuK on 2019-11-13.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import XCTest
import Web3
import CryptoSwift
import DMS_HDWallet_Cocoa

class Web3Tests: XCTestCase {

    var web3: Web3!

    override func setUp() {
        // rinkeby
        // let web3 = Web3(rpcURL: "https://rinkeby.infura.io/v3/823d2b1356e24d7fbd3b1ae954c6db19")
        
        // local
        // let web3 = Web3(rpcURL: "HTTP://127.0.0.1:7545")
        web3 = Web3(rpcURL: "HTTP://127.0.0.1:8545")
    }

    func testSmoke() {

    }

    func testClientVersion() {
        // ropsten
        let web3 = Web3(rpcURL: "https://ropsten.infura.io/v3/823d2b1356e24d7fbd3b1ae954c6db19")
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
        // ropsten
        let web3 = Web3(rpcURL: "https://ropsten.infura.io/v3/823d2b1356e24d7fbd3b1ae954c6db19")
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
        // ropsten
        let web3 = Web3(rpcURL: "https://ropsten.infura.io/v3/823d2b1356e24d7fbd3b1ae954c6db19")
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
    
}

extension Web3Tests {

    func testBalance() {
        // ropsten
        let web3 = Web3(rpcURL: "https://ropsten.infura.io/v3/823d2b1356e24d7fbd3b1ae954c6db19")
        
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

extension Web3Tests {
    
    func testTransfer() {
        let expect = expectation(description: "")

        let fromPrivateKey = ""
        if fromPrivateKey.isEmpty { return }
        
        let fromAddressPrivateKey = try! EthereumPrivateKey(hexPrivateKey: fromPrivateKey)
        let toEthereumAddress = try! EthereumAddress(hex: "0x16BE9bC703c942574b407Fb1CB512CAeC5F5a0d9", eip55: false)

        firstly {
            web3.eth.getTransactionCount(address: fromAddressPrivateKey.address, block: .latest)
        }.done { nonce in
            let transaction = EthereumTransaction(
                nonce: nonce,
                gasPrice: EthereumQuantity(quantity: 1.gwei),
                gas: 21000,
                to: toEthereumAddress,
                value: EthereumQuantity(quantity: BigUInt(10).power(18)))       // 0.1 ETH
            let signedTransaction = try! transaction.sign(with: fromAddressPrivateKey, chainId: 4)
            
            self.web3.eth.sendRawTransaction(transaction: signedTransaction) { response in
                XCTAssertNotNil(response.result)
                expect.fulfill()
            }
        }.catch { error in
            XCTFail(error.localizedDescription)
        }

        wait(for: [expect], timeout: 30.0)
    }
    
}

extension Web3Tests {
    
    func testDeoplyContact() {
        let chainID: EthereumQuantity = 4   // rinkeby
        
        let contractABIData: Data = {
            let path = Bundle(for: Web3Tests.self).path(forResource: "redpacket", ofType: "json")
            let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
            return data
        }()
        let contract = try! web3.eth.Contract(json: contractABIData, abiKey: nil, address: nil)
        let contractByteCode: EthereumData = {
            let path = Bundle(for: Web3Tests.self).path(forResource: "redpacket", ofType: "bin")
            let bytesString = try! String(contentsOfFile: path!)
            return try! EthereumData(ethereumValue: bytesString.trimmingCharacters(in: .whitespacesAndNewlines))
        }()
        
        
        let parameters: [ABIEncodable] = {
            let _hashes: [BigUInt] = {
                let uuid = UUID().uuidString    // UUID. keep it down and use later
                let hash = SHA3(variant: .keccak256).calculate(for: uuid.bytes)
                print("\(uuid): \(hash.toHexString())")
                return [BigUInt(hash)]
            }()
            
            let ifrandom: Bool = true
            let expirationTime: BigUInt = {
                let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
                return BigUInt(nextWeek.timeIntervalSince1970)
            }()
           
            return [_hashes, ifrandom, expirationTime]
        }()
        
        // Check contract 
        guard let invocation = contract.deploy(byteCode: contractByteCode, parameters: parameters) else {
            XCTFail()
            return
        }
        
        XCTAssertNotNil(contract.constructor)
        XCTAssertEqual(invocation.parameters.count, 3)
        XCTAssertEqual(invocation.byteCode, contractByteCode)
        
        
        // Ganache test account
        let mnemonic = ["flower", "parent", "dizzy", "mercy", "sentence", "wall", "weird", "measure", "chicken", "shoulder", "broom", "island"]
        let wallet = try! HDWallet(mnemonic: mnemonic, passphrase: "", network: .mainnet(.ether))
        let address = try! wallet.address()
        let ethereumAddress = try! EthereumAddress(hex: address, eip55: false)

        // Get transaction nonce
        var nonce: EthereumQuantity? = nil
        let nonceExpectation = expectation(description: "nonce")
        web3.eth.getTransactionCount(address: ethereumAddress, block: .latest) { response in
            nonce = response.result
            nonceExpectation.fulfill()
        }
        wait(for: [nonceExpectation], timeout: 10.0)
        XCTAssertNotNil(nonce)
        
        // create deploy contract transaction
        let value = EthereumQuantity(quantity: 200000.gwei)
        let transaction = invocation.createTransaction(nonce: nonce, from: ethereumAddress, value: value, gas: 3000000, gasPrice: EthereumQuantity(quantity: 1.gwei))
        let generatedHexString = transaction?.data.hex()
        XCTAssertNotNil(generatedHexString)

        // sign transaction
        let hexPrivateKey = try! wallet.privateKey().key.toHexString()
        let privateKey = try! EthereumPrivateKey(hexPrivateKey: "0x" + hexPrivateKey)
        XCTAssertNotNil(transaction)
        let signedTransaction = try! transaction!.sign(with: privateKey, chainId: chainID)
        XCTAssertNotNil(signedTransaction)
        
        // send transaction
        let deployExpectation = expectation(description: "delpoy")
        web3.eth.sendRawTransaction(transaction: signedTransaction) { response in
            switch response.status {
            case let .success(data):
                print(data.hex())
                deployExpectation.fulfill()

            case let .failure(error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [deployExpectation], timeout: 300)
    }
    
    func testClaim() {
        let chainID: EthereumQuantity = 4   // rinkeby
        let uuid = "AFDF65A9-F419-4BD6-A924-1D209695F3C8"
        
        // Ganache test account
        let mnemonic = ["flower", "parent", "dizzy", "mercy", "sentence", "wall", "weird", "measure", "chicken", "shoulder", "broom", "island"]
        let wallet = try! HDWallet(mnemonic: mnemonic, passphrase: "", network: .mainnet(.ether))
        let address = try! wallet.address()
        let ethereumAddress = try! EthereumAddress(hex: address, eip55: false)
        
        let hexPrivateKey = try! wallet.privateKey().key.toHexString()
        let privateKey = try! EthereumPrivateKey(hexPrivateKey: "0x" + hexPrivateKey)
        
        let contractABIData: Data = {
            let path = Bundle(for: Web3Tests.self).path(forResource: "redpacket", ofType: "json")
            let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
            return data
        }()
        let contractAddress = try! EthereumAddress(hex: "0xf6b38ff43ec872fa0c02a2ebf9099ca4f1e5eecf", eip55: false)
        let contract = try! web3.eth.Contract(json: contractABIData, abiKey: nil, address: contractAddress)
        
        let claimCall = contract["claim"]
        XCTAssertNotNil(claimCall)
        
        // Get transaction nonce
        var nonce: EthereumQuantity? = nil
        let nonceExpectation = expectation(description: "nonce")
        web3.eth.getTransactionCount(address: ethereumAddress, block: .latest) { response in
            nonce = response.result
            nonceExpectation.fulfill()
        }
        wait(for: [nonceExpectation], timeout: 10.0)
        XCTAssertNotNil(nonce)
        
        // Build contract method call transaction
        let claimInvocation = claimCall!(uuid, BigUInt.randomInteger(withMaximumWidth: 32))
        let claimTransaction = claimInvocation.createTransaction(nonce: nonce, from: ethereumAddress, value: 0, gas: 210000, gasPrice: EthereumQuantity(quantity: 1.gwei))
        XCTAssertNotNil(claimTransaction)
        let signedClaimTransaction = try! claimTransaction!.sign(with: privateKey, chainId: chainID)
        XCTAssertNotNil(signedClaimTransaction)
        
        // Send signed contract method call transaction
        let callExpectation = expectation(description: "call")
        var transactionHash: EthereumData? = nil
        web3.eth.sendRawTransaction(transaction: signedClaimTransaction) { data in
            // print(data.result?.hex())
            if let hash = data.result {
                callExpectation.fulfill()
                transactionHash = data.result
            } else {
                XCTFail()
            }
        }
        wait(for: [callExpectation], timeout: 30)
        
        XCTAssertNotNil(transactionHash)
        
        // Check emitted event log
        let receiptExpectation = expectation(description: "receiptExpectation")
        web3.eth.getTransactionReceipt(transactionHash: transactionHash!) { response in
            guard let receipt = response.result else {
                XCTFail()
                return
            }
            
            guard let logs = receipt?.logs else {
                XCTFail()
                return
            }
            
            for event in contract.events {
                for log in logs {
                    let result = try? ABI.decodeLog(event: event, from: log)
                    print(event.name)
                    print(result)
                }
            }
            
            receiptExpectation.fulfill()
        }
        wait(for: [receiptExpectation], timeout: 10)
    }
    
}


//extension EthereumAddress {
//    static let testAddress = try! EthereumAddress(hex: "0x0000000000000000000000000000000000000000", eip55: false)
//}
