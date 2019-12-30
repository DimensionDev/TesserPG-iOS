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
    var chainID: EthereumQuantity!
    
    let contractABIData: Data = {
        let path = Bundle(for: Web3Tests.self).path(forResource: "redpacket", ofType: "json")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        return data
    }()
    let contractByteCode: EthereumData = {
        let path = Bundle(for: Web3Tests.self).path(forResource: "redpacket", ofType: "bin")
        let bytesString = try! String(contentsOfFile: path!)
        return try! EthereumData(ethereumValue: bytesString.trimmingCharacters(in: .whitespacesAndNewlines))
    }()

    override func setUp() {
        // rinkeby
        web3 = Web3(rpcURL: "https://rinkeby.infura.io/v3/823d2b1356e24d7fbd3b1ae954c6db19")
        chainID = 4   // rinkeby
        
        // local
        // let web3 = Web3(rpcURL: "HTTP://127.0.0.1:7545")
        // web3 = Web3(rpcURL: "HTTP://127.0.0.1:8545")
    }

    func testSmoke() {

    }
    
    func testCreateWallet() {
        let mnemonic = Mnemonic.create()
        print(mnemonic)
        let wallet = try! HDWallet(mnemonic: mnemonic, passphrase: "dimension", network: .mainnet(.ether))
        print(try! wallet.address())
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

        // Rinkeby test account
        let mnemonic = ["ensure", "fossil", "scan", "dash", "tomato", "country", "draft", "organ", "loud", "garbage", "keen", "cat"]
        let passphrase = "dimension"
        
        // Ganache test account
        // let mnemonic = ["flower", "parent", "dizzy", "mercy", "sentence", "wall", "weird", "measure", "chicken", "shoulder", "broom", "island"]
        // let passphrase = ""
        let wallet = try! HDWallet(mnemonic: mnemonic, passphrase: passphrase, network: .mainnet(.ether))
        let address = try! wallet.address()
        // let ethereumAddress = try! EthereumAddress(hex: address, eip55: false)
        
        let hexPrivateKey = try! wallet.privateKey().key.toHexString()
        let privateKey = try! EthereumPrivateKey(hexPrivateKey: "0x" + hexPrivateKey)
        let fromAddressPrivateKey = privateKey
        
        let toEthereumAddress = try! EthereumAddress(hex: "0xDB07c331Bd039f89CC22E0294eE6829Fdaca658e", eip55: false)

        firstly {
            web3.eth.getTransactionCount(address: fromAddressPrivateKey.address, block: .latest)
        }.done { nonce in
            let transaction = EthereumTransaction(
                nonce: nonce,
                gasPrice: EthereumQuantity(quantity: 1.gwei),
                gas: 21000,
                to: toEthereumAddress,
                value: EthereumQuantity(quantity: 1 * BigUInt(10).power(16)))       // 0.01 ETH
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
        let contract = try! web3.eth.Contract(json: contractABIData, abiKey: nil, address: nil)
        
        // Check contract 
        guard let invocation = contract.deploy(byteCode: contractByteCode, parameters: []) else {
            XCTFail()
            return
        }
        
        XCTAssertNotNil(contract.constructor)
        XCTAssertEqual(invocation.parameters.count, 0)
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
        let transaction = invocation.createTransaction(nonce: nonce, from: ethereumAddress, value: 0, gas: 3000000, gasPrice: EthereumQuantity(quantity: 1.gwei))
        let generatedHexString = transaction?.data.hex()
        XCTAssertNotNil(generatedHexString)

        // sign transaction
        let hexPrivateKey = try! wallet.privateKey().key.toHexString()
        let privateKey = try! EthereumPrivateKey(hexPrivateKey: "0x" + hexPrivateKey)
        XCTAssertNotNil(transaction)
        let signedTransaction = try! transaction!.sign(with: privateKey, chainId: chainID)
        XCTAssertNotNil(signedTransaction)
        
        var transactionHash: EthereumData?
        // send contract deploy transaction
        let deployExpectation = expectation(description: "delpoy")
        web3.eth.sendRawTransaction(transaction: signedTransaction) { response in
            switch response.status {
            case let .success(data):
                transactionHash = data
                deployExpectation.fulfill()

            case let .failure(error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [deployExpectation], timeout: 30)
        
        
        XCTAssertNotNil(transactionHash)
        print("Delpoy transactionHash: " + transactionHash!.hex())
    }
    
    func testDelpoyTransactionResult() {
        let transactionHashHex = "0xd8e4db3342e51cf4f8ef2d62e546ae25d08488eaf9c321b8eae584b492bad819"
        let transactionHash = EthereumData(Bytes(hex: transactionHashHex))
        
        var contractAddress: EthereumData?
        let contractExpectation = expectation(description: "contractExpectation")
        web3.eth.getTransactionReceipt(transactionHash: transactionHash) { response in
            guard let result = response.result else {
                XCTFail()
                return
            }
            
            // 1 success
            // 0 failure
            XCTAssertEqual(result?.status?.quantity, 1)

            contractAddress = result?.contractAddress
            XCTAssertNotNil(contractAddress)
            print("Contract address: \(contractAddress?.hex() ?? "nil")")
            contractExpectation.fulfill()

        }
        wait(for: [contractExpectation], timeout: 30)
    }
    
    func testCreate() {
        // create 2 share random mode red packet with total 0.01 ETH
        let chainID: EthereumQuantity = 4   // rinkeby

        let contractAddressHex = "0xc7e0fcc5f50550102a7c85e108291f14502fb574"
        let contractAddress = try! EthereumAddress(hex: contractAddressHex, eip55: false)
        let contract = try! web3.eth.Contract(json: contractABIData, abiKey: nil, address: contractAddress)

        let createCall = contract["create_red_packet"]
        XCTAssertNotNil(createCall)
        
        // Rinkeby test account
        let mnemonic = ["ensure", "fossil", "scan", "dash", "tomato", "country", "draft", "organ", "loud", "garbage", "keen", "cat"]
        let passphrase = "dimension"
        
        // Ganache test account
        // let mnemonic = ["flower", "parent", "dizzy", "mercy", "sentence", "wall", "weird", "measure", "chicken", "shoulder", "broom", "island"]
        // let passphrase = ""
        
        let wallet = try! HDWallet(mnemonic: mnemonic, passphrase: passphrase, network: .mainnet(.ether))
        let address = try! wallet.address()
        let ethereumAddress = try! EthereumAddress(hex: address, eip55: false)
        
        let hexPrivateKey = try! wallet.privateKey().key.toHexString()
        let privateKey = try! EthereumPrivateKey(hexPrivateKey: "0x" + hexPrivateKey)
        
        // Get transaction nonce
        var nonce: EthereumQuantity? = nil
        let nonceExpectation = expectation(description: "nonce")
        web3.eth.getTransactionCount(address: ethereumAddress, block: .latest) { response in
            nonce = response.result
            nonceExpectation.fulfill()
        }
        wait(for: [nonceExpectation], timeout: 10.0)
        XCTAssertNotNil(nonce)
        
        // prepare create call parameters
        let uuids = [
            "8090D64A-03A6-4E2A-B457-9A0376696F8E",
            "338D6AE4-F1BC-40CD-B036-0210686F5585",
        ]
        let _hashes: [BigUInt] = uuids.map { uuid in
            let hash = SHA3(variant: .keccak256).calculate(for: uuid.bytes)
            print("\(uuid): \(hash.toHexString())")
            return BigUInt(hash)
        }
        let ifrandom = true
        let duration: BigUInt = 86400
        let seed = BigUInt.randomInteger(withMaximumWidth: 32)
        let message = "Message"
        let name = "Name"
        
        let value = EthereumQuantity(quantity: 1 * BigUInt(10).power(16))       // 0.01 ETH
        
        // Build contract method call transaction
        let createInvocation = createCall!(_hashes, ifrandom, duration, seed, message, name)
        let createTransaction = createInvocation.createTransaction(nonce: nonce, from: ethereumAddress, value: value, gas: 4300000, gasPrice: EthereumQuantity(quantity: 1.gwei))
        XCTAssertNotNil(createTransaction)
        
        let signedCreateTransaction = try! createTransaction!.sign(with: privateKey, chainId: chainID)
        XCTAssertNotNil(signedCreateTransaction)
        
        // Send signed contract method call transaction
        let callExpectation = expectation(description: "call")
        var transactionHash: EthereumData? = nil
        web3.eth.sendRawTransaction(transaction: signedCreateTransaction) { data in
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
        print("Create transactionHash: " + transactionHash!.hex())
    }
    
    func testCreateResult() {
        let contractAddressHex = "0xc7e0fcc5f50550102a7c85e108291f14502fb574"
        let contractAddress = try! EthereumAddress(hex: contractAddressHex, eip55: false)
        let contract = try! web3.eth.Contract(json: contractABIData, abiKey: nil, address: contractAddress)
        
        let transactionHashHex = "0x79dc96432bcdc0a68b36360eacb601af6a75bcf1db4b397b11709b46688a1270"
        let transactionHash = EthereumData(Bytes(hex: transactionHashHex))
        
        let check = Web3Tests.checkClaimEvent(web3: web3, contract: contract, transactionHash: transactionHash, in: self)
        wait(for: [check], timeout: 30)
    }
    
    // FIXME: Reproduce Attack
    func testClaim() {
        // 8090D64A-03A6-4E2A-B457-9A0376696F8E: e8d00d64ea4f3e30fc4852ca85b8bc4f197f156f8d82b15dc4ce382997071e49
        // 338D6AE4-F1BC-40CD-B036-0210686F5585: 0c527fcadc18c377b7abcd9de269aaa4e511320d596e89f3ca624524e0cb2b87
        // id: 36861d077060b1865ea0845e0707dae7f9e5d021b62fe95668989f0c567325eb
        let chainID: EthereumQuantity = 4   // rinkeby
    
        let contractAddressHex = "0xc7e0fcc5f50550102a7c85e108291f14502fb574"
        let uuids = [
            "8090D64A-03A6-4E2A-B457-9A0376696F8E",
            "338D6AE4-F1BC-40CD-B036-0210686F5585",
        ]
        let uuid = uuids[0]
        
        // Rinkeby test account
        // let mnemonic = ["ensure", "fossil", "scan", "dash", "tomato", "country", "draft", "organ", "loud", "garbage", "keen", "cat"]
        let mnemonic = ["blood", "grunt", "risk", "wing", "surface", "expire", "paper", "elite", "phrase", "very", "rival", "earth"]
        let passphrase = "dimension"
        
        // Ganache test account
        // let mnemonic = ["flower", "parent", "dizzy", "mercy", "sentence", "wall", "weird", "measure", "chicken", "shoulder", "broom", "island"]
        // let passphrase = ""
        
        let wallet = try! HDWallet(mnemonic: mnemonic, passphrase: passphrase, network: .mainnet(.ether))
        let address = try! wallet.address()
        let ethereumAddress = try! EthereumAddress(hex: address, eip55: false)
        
        let hexPrivateKey = try! wallet.privateKey().key.toHexString()
        let privateKey = try! EthereumPrivateKey(hexPrivateKey: "0x" + hexPrivateKey)
        
        // contract
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
        
        // Red Packet ID
        let id = BigUInt(hexString: "6a3127839906cc37afb11002c662c0957a089c9302f6bfd776bed09588635a0a")
        XCTAssertNotNil(id)
        
        let recipient = ethereumAddress
        let validationBytes = SHA3(variant: .keccak256).calculate(for: try! recipient.makeBytes())
        let validation = BigUInt(validationBytes)
        
        let name = "Alice"
        
        // Build contract method call transaction
        let claimInvocation = claimCall!(id!, uuid, recipient, validation, name)
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
        print("Claim transactionHash: " + transactionHash!.hex())
    }
    
    func testClaimResult() {
        let contractAddressHex = "0xc7e0fcc5f50550102a7c85e108291f14502fb574"
        let contractAddress = try! EthereumAddress(hex: contractAddressHex, eip55: false)
        let contract = try! web3.eth.Contract(json: contractABIData, abiKey: nil, address: contractAddress)
        
        // 1st claimed on uuid[0]: claim transactionHash 0x2e294556131657c3d45aac24d61380bb8cae9dc148180223d4e2bb2b72ce0c21 ClaimSuccess
        // 2nd claimed on uuid[0]: claim transactionHash 0xcdc9f3b81041d6266d5da96e8e9179e82d1f2c3ec3877a723dbde5df0ffb1e1c Status: 0 Failure
        let transactionHashHex = "0xcdc9f3b81041d6266d5da96e8e9179e82d1f2c3ec3877a723dbde5df0ffb1e1c"
        let transactionHash = EthereumData(Bytes(hex: transactionHashHex))
        
        let check = Web3Tests.checkClaimEvent(web3: web3, contract: contract, transactionHash: transactionHash, in: self)
        wait(for: [check], timeout: 30)
    }
    
    static func checkClaimEvent(web3: Web3, contract: EthereumContract, transactionHash: EthereumData, in testCase: XCTestCase) -> XCTestExpectation {
        // Check emitted event log
        let checkExpectation = testCase.expectation(description: "receiptExpectation")
        web3.eth.getTransactionReceipt(transactionHash: transactionHash) { response in
            guard let receipt = response.result else {
                XCTFail()
                return
            }
            
            guard let status = receipt?.status else {
                XCTFail()
                return
            }
            
            if status.quantity == 0 {
                print("Status: 0 [failure]")
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
                    
                    if event.name == "CreationSuccess" {
                        if let idData = result?["id"] as? Data, idData.count == 32 {
                            print("id: \(idData.toHexString())")
                        }
                    }
                }
            }
            
            checkExpectation.fulfill()
        }
        
        return checkExpectation
    }
    
    func testCheckAvaiability() {
        let contractAddressHex = "0xc7e0fcc5f50550102a7c85e108291f14502fb574"
        let contractAddress = try! EthereumAddress(hex: contractAddressHex, eip55: false)
        let contract = try! web3.eth.Contract(json: contractABIData, abiKey: nil, address: contractAddress)
    
        let checkAvailabilityExpectation = expectation(description: "check_availability")
        
        let id = BigUInt(hexString: "6a3127839906cc37afb11002c662c0957a089c9302f6bfd776bed09588635a0a")
        XCTAssertNotNil(id)
        
        let checkAvailabilityInvocation = contract["check_availability"]!(id!)
        
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
        let contractAddressHex = "0xc7e0fcc5f50550102a7c85e108291f14502fb574"
        let contractAddress = try! EthereumAddress(hex: contractAddressHex, eip55: false)
        let contract = try! web3.eth.Contract(json: contractABIData, abiKey: nil, address: contractAddress)
        
        let checkClaimedListExpectation = expectation(description: "check_claimed_list")
        
        let id = BigUInt(hexString: "6a3127839906cc37afb11002c662c0957a089c9302f6bfd776bed09588635a0a")
        XCTAssertNotNil(id)
        let checkClaimedListInvocation = contract["check_claimed_list"]!(id!)
                
        checkClaimedListInvocation.call { resultDict, error in
            XCTAssertNil(error)
            guard let dict = resultDict else {
                XCTFail()
                return
            }
            
            print(dict)
            checkClaimedListExpectation.fulfill()
            
        }
    
        wait(for: [checkClaimedListExpectation], timeout: 30.0)
    }
    
    func testRefund() {
        let contractAddressHex = "0xc7e0fcc5f50550102a7c85e108291f14502fb574"
        let contractAddress = try! EthereumAddress(hex: contractAddressHex, eip55: false)
        let contract = try! web3.eth.Contract(json: contractABIData, abiKey: nil, address: contractAddress)
        
        let refundCall = contract["refund"]
        XCTAssertNotNil(refundCall)
        
        // Rinkeby test account
        let mnemonic = ["ensure", "fossil", "scan", "dash", "tomato", "country", "draft", "organ", "loud", "garbage", "keen", "cat"]
        let passphrase = "dimension"
        
        // Ganache test account
        // let mnemonic = ["flower", "parent", "dizzy", "mercy", "sentence", "wall", "weird", "measure", "chicken", "shoulder", "broom", "island"]
        // let passphrase = ""
        
        let wallet = try! HDWallet(mnemonic: mnemonic, passphrase: passphrase, network: .mainnet(.ether))
        let address = try! wallet.address()
        let ethereumAddress = try! EthereumAddress(hex: address, eip55: false)
        
        let hexPrivateKey = try! wallet.privateKey().key.toHexString()
        let privateKey = try! EthereumPrivateKey(hexPrivateKey: "0x" + hexPrivateKey)
        
        // Get transaction nonce
        var nonce: EthereumQuantity? = nil
        let nonceExpectation = expectation(description: "nonce")
        web3.eth.getTransactionCount(address: ethereumAddress, block: .latest) { response in
            nonce = response.result
            nonceExpectation.fulfill()
        }
        wait(for: [nonceExpectation], timeout: 10.0)
        XCTAssertNotNil(nonce)
        
        // Build refund method call transaction
        let id = BigUInt(hexString: "6a3127839906cc37afb11002c662c0957a089c9302f6bfd776bed09588635a0a")
        XCTAssertNotNil(id)
        let refundInvocation = refundCall!(id!)
        let refundTrasaction = refundInvocation.createTransaction(nonce: nonce, from: ethereumAddress, value: 0, gas: 430000, gasPrice: EthereumQuantity(quantity: 1.gwei))
        XCTAssertNotNil(refundTrasaction)
        
        let signedRefundTransaction = try! refundTrasaction?.sign(with: privateKey, chainId: chainID)
        XCTAssertNotNil(signedRefundTransaction)
        
        let callExpectation = expectation(description: "call")
        var transactionHash: EthereumData?
        web3.eth.sendRawTransaction(transaction: signedRefundTransaction!) { response in
            switch response.status {
            case let .success(data):
                transactionHash = data
                callExpectation.fulfill()
            case let .failure(error):
                XCTFail(error.localizedDescription)
            }
        }
        
        wait(for: [callExpectation], timeout: 15.0)
        
        XCTAssertNotNil(transactionHash)
        print("Refund transactionHash: \(transactionHash!.hex())")
    }
    
    func testRefundResult() {
        let contractAddressHex = "0xc7e0fcc5f50550102a7c85e108291f14502fb574"
        let contractAddress = try! EthereumAddress(hex: contractAddressHex, eip55: false)
        let contract = try! web3.eth.Contract(json: contractABIData, abiKey: nil, address: contractAddress)
        
        let transactionHashHex = "0xa54682a8f7899908d7a49735a3977d3f7754e80ecac765f8e62d7f4e358dd3d1"
        let transactionHash = EthereumData(Bytes(hex: transactionHashHex))
        
        let check = Web3Tests.checkClaimEvent(web3: web3, contract: contract, transactionHash: transactionHash, in: self)
        wait(for: [check], timeout: 30)
    }
    
}

extension Web3Tests {
    
    func testCheckRevertReason() {
        // already claimed      0xc27710400f2a31182d4be92dd21c09dcab66926ed95a9ad626b544104fa0109b 5594385
        // success              0x150f20b37f633a0cad62c006c2d8c7e35a303bb64ca61a07375d4d3e34119045 5594374
        // expired              0x56205392450266364aa1772e4c42990f46410d16ddfa8667a5311e23f1ce8b51 5583193
        // 008 Disallowed until the expiration time has passed
        //                      0x1886fc2d4882b5fea48a32b98518f65ed03883efdce78b9dcf2a581df0663a6a 5599901
        // 005 Already Claimed  0xed32c3350c25bd5728d4e5580909a4ecae60b3af345abf1244ad1bdedab60845 5599962
        // 009 Diallowed until the expiration time has passed
        //                      0xa54682a8f7899908d7a49735a3977d3f7754e80ecac765f8e62d7f4e358dd3d1
        let transactionHashHex = "0xa54682a8f7899908d7a49735a3977d3f7754e80ecac765f8e62d7f4e358dd3d1"
        let transactionHash = EthereumData(Bytes(hex: transactionHashHex))
        
        let transactionObjectExpectation = expectation(description: "transactino object")
        var transactionObject: EthereumTransactionObject?
        web3.eth.getTransactionByHash(blockHash: transactionHash) { response in
            switch response.status {
            case let .success(object):
                transactionObject = object
                transactionObjectExpectation.fulfill()
            case let .failure(error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [transactionObjectExpectation], timeout: 15)
        
        XCTAssertNotNil(transactionObject)
        
        let call = EthereumCall(from: transactionObject!.from,
                     to: transactionObject!.to!,
                     gas: 500000,
                     gasPrice: transactionObject!.gasPrice,
                     value: 0,
                     data: transactionObject!.input)
        let block = try! EthereumQuantityTag.block(transactionObject!.blockNumber!.quantity)
        
        let reasonDataExpectation = expectation(description: "revert reason")
        var reasonData: EthereumData?       // revert reason
        
        web3.eth.call(call: call, block: block) { result in
            switch result.status {
            case let .success(data):
                reasonData = data
                reasonDataExpectation.fulfill()
            case let .failure(error):
                XCTFail(error.localizedDescription)
            }
        }
        
        wait(for: [reasonDataExpectation], timeout: 15)
        guard var bytes = reasonData?.bytes else {
            XCTFail()
            return
        }
        
        // e.g.
        // 08c379a00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000f416c726561647920436c61696d65640000000000000000000000000000000000
        let hex = bytes.toHexString() // Sha3("Error(string)")
        let parameter = SolidityFunctionParameter(name: "Error", type: .string)
        
        let data = Data(bytes)
        let signature = data.prefix(4).toHexString()
        guard signature == "08c379a0" else {
            XCTFail()
            return
        }
        
        var buffer = data
        buffer.removeFirst(4)
        
        let offsetData: Data = buffer.prefix(32)
        let offsetString = String(BigUInt(offsetData))
        let offset = Int(offsetString) ?? -1
        
        buffer.removeFirst(32)
        let lengthData: Data = buffer.prefix(32)
        let lengthString = String(BigUInt(lengthData))
        let length = Int(lengthString) ?? -1
                
        guard offset > 0, length > 0 else {
            XCTFail()
            return
        }
        
        buffer.removeFirst(32)
        let stringData = buffer.prefix(length)
        guard let revertReason = String(data: stringData, encoding: .ascii) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(revertReason, "008 Disallowed until the expiration time has passed")
    }
    
}

extension Web3Tests {
    
}
