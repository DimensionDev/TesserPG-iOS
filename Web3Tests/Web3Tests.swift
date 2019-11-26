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
        web3 = Web3(rpcURL: "https://rinkeby.infura.io/v3/823d2b1356e24d7fbd3b1ae954c6db19")
        
        // local
        // let web3 = Web3(rpcURL: "HTTP://127.0.0.1:7545")
        // web3 = Web3(rpcURL: "HTTP://127.0.0.1:8545")
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
            let uuids = [UUID().uuidString, UUID().uuidString]
            let _hashes: [BigUInt] = uuids.map { uuid in
                let hash = SHA3(variant: .keccak256).calculate(for: uuid.bytes)
                print("\(uuid): \(hash.toHexString())")
                return BigUInt(hash)
            }
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
        
        // Rinkeby test account
        let mnemonic = ["ensure", "fossil", "scan", "dash", "tomato", "country", "draft", "organ", "loud", "garbage", "keen", "cat"]
        let passphrase = "dimension"
        
        // Ganache test account
        // let mnemonic = ["flower", "parent", "dizzy", "mercy", "sentence", "wall", "weird", "measure", "chicken", "shoulder", "broom", "island"]
        // let passphrase = ""
        let wallet = try! HDWallet(mnemonic: mnemonic, passphrase: passphrase, network: .mainnet(.ether))
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
        let minValue: BigUInt = 1000000.gwei    // 0.001 eth
        let value = EthereumQuantity(quantity: 2 * minValue)
        let transaction = invocation.createTransaction(nonce: nonce, from: ethereumAddress, value: value, gas: 3000000, gasPrice: EthereumQuantity(quantity: 1.gwei))
        let generatedHexString = transaction?.data.hex()
        XCTAssertNotNil(generatedHexString)

        // sign transaction
        let hexPrivateKey = try! wallet.privateKey().key.toHexString()
        let privateKey = try! EthereumPrivateKey(hexPrivateKey: "0x" + hexPrivateKey)
        XCTAssertNotNil(transaction)
        let signedTransaction = try! transaction!.sign(with: privateKey, chainId: chainID)
        XCTAssertNotNil(signedTransaction)
        
        var transactionHash: EthereumData?
        // send transaction
        let deployExpectation = expectation(description: "delpoy")
        web3.eth.sendRawTransaction(transaction: signedTransaction) { response in
            switch response.status {
            case let .success(data):
                print(data.hex())
                transactionHash = data
                deployExpectation.fulfill()

            case let .failure(error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [deployExpectation], timeout: 30)
        
        var contractAddress: EthereumData?
        let contractExpectation = expectation(description: "contractExpectation")
        XCTAssertNotNil(transactionHash)
        web3.eth.getTransactionReceipt(transactionHash: transactionHash!) { response in
            guard let result = response.result else {
                XCTFail()
                return
            }
            
            contractAddress = result?.contractAddress
            XCTAssertNotNil(contractAddress)
            print("Contract: \(contractAddress?.hex() ?? "nil")")
            contractExpectation.fulfill()
            
        }
        wait(for: [contractExpectation], timeout: 30)
    }
    
    func testClaim() {
//        8090D64A-03A6-4E2A-B457-9A0376696F8E: e8d00d64ea4f3e30fc4852ca85b8bc4f197f156f8d82b15dc4ce382997071e49
//        338D6AE4-F1BC-40CD-B036-0210686F5585: 0c527fcadc18c377b7abcd9de269aaa4e511320d596e89f3ca624524e0cb2b87
//        0x77eea65e929f6dd14dc9629be29418057078551247baa41a4c02dfc5fe6a0c52
        let chainID: EthereumQuantity = 4   // rinkeby
        let contractAddressHex = "0x1d3a88693d408f8a7add6c5d975f13a743f1c71d"
        let uuid = "338D6AE4-F1BC-40CD-B036-0210686F5585"
        
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
        let contractAddress = try! EthereumAddress(hex: contractAddressHex, eip55: false)
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
        print(transactionHash)
        
        let check = Web3Tests.checkClaimEvent(web3: web3, contract: contract, transactionHash: transactionHash!, in: self)
        wait(for: [check], timeout: 30)
    }
    
    func testCheckClaimEvent() {
        let contractAddressHex = "0x87c2d764950754bebdc3d0fb7a93c61862826497"
        let transactionHash = EthereumData(Data(hex: "0xcfc06f9ba00671982bda3220de19ac8400fc4125e8c4b2b590fcab0f18542bff").bytes)
        
        let contractABIData: Data = {
            let path = Bundle(for: Web3Tests.self).path(forResource: "redpacket", ofType: "json")
            let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
            return data
        }()
        let contractAddress = try! EthereumAddress(hex: contractAddressHex, eip55: false)
        let contract = try! web3.eth.Contract(json: contractABIData, abiKey: nil, address: contractAddress)
        
        // Check emitted event log
        let receiptExpectation = expectation(description: "receiptExpectation")
        web3.eth.getTransactionReceipt(transactionHash: transactionHash) { response in
            guard let receipt = response.result else {
                XCTFail()
                return
            }
            
            guard let logs = receipt?.logs else {
                XCTFail()
                return
            }
            
            print(receipt?.logs)
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
    
    static func checkClaimEvent(web3: Web3, contract: EthereumContract, transactionHash: EthereumData, in testCase: XCTestCase) -> XCTestExpectation {
        // Check emitted event log
        let checkExpectation = testCase.expectation(description: "receiptExpectation")
        web3.eth.getTransactionReceipt(transactionHash: transactionHash) { response in
            guard let receipt = response.result else {
                XCTFail()
                return
            }
            
            guard let logs = receipt?.logs else {
                XCTFail()
                return
            }
            
            print(receipt?.logs)
            for event in contract.events {
                for log in logs {
                    let result = try? ABI.decodeLog(event: event, from: log)
                    print(event.name)
                    print(result)
                }
            }
            
            checkExpectation.fulfill()
        }
        
        return checkExpectation
    }
    
    func testCheckAvaiability() {
        let contractAddressHex = "0x744a327ab72fd77d7d7cc293f6d24e25ac03c803"
        // let transactionHash = EthereumData(Data(hex: "0xcfc06f9ba00671982bda3220de19ac8400fc4125e8c4b2b590fcab0f18542bff").bytes)
        
        let contractABIData: Data = {
            let path = Bundle(for: Web3Tests.self).path(forResource: "redpacket", ofType: "json")
            let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
            return data
        }()
        let contractAddress = try! EthereumAddress(hex: contractAddressHex, eip55: false)
        let contract = try! web3.eth.Contract(json: contractABIData, abiKey: nil, address: contractAddress)
    
        
        let checkAvailabilityExpectation = expectation(description: "check_availability")
        let checkAvailabilityInvocation = contract["check_availability"]!()
        
        checkAvailabilityInvocation.method.outputs
        
        checkAvailabilityInvocation.call { resultDict, error in
            guard let dict = resultDict else {
                XCTFail()
                return
            }
            
            print(dict)
            checkAvailabilityExpectation.fulfill()
            
        }
    
        wait(for: [checkAvailabilityExpectation], timeout: 30.0)
    }
    
    func testCheckClaimedList() {
        let contractAddressHex = "0x87c2d764950754bebdc3d0fb7a93c61862826497"
        // let transactionHash = EthereumData(Data(hex: "0xcfc06f9ba00671982bda3220de19ac8400fc4125e8c4b2b590fcab0f18542bff").bytes)
        
        let contractABIData: Data = {
            let path = Bundle(for: Web3Tests.self).path(forResource: "redpacket", ofType: "json")
            let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
            return data
        }()
        let contractAddress = try! EthereumAddress(hex: contractAddressHex, eip55: false)
        let contract = try! web3.eth.Contract(json: contractABIData, abiKey: nil, address: contractAddress)
    
        
        let checkClaimedListExpectation = expectation(description: "check_claimed_list")
        let checkClaimedListInvocation = contract["check_claimed_list"]!()
        
        checkClaimedListInvocation.method.outputs
        
        checkClaimedListInvocation.call { resultDict, error in
            guard let dict = resultDict else {
                XCTFail()
                return
            }
            
            print(dict)
            checkClaimedListExpectation.fulfill()
            
        }
    
        wait(for: [checkClaimedListExpectation], timeout: 30.0)
    }
    
}

