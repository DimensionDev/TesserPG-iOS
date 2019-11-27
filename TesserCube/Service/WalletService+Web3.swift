//
//  WalletService+Web3.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-13.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import Foundation
import RxSwift
import CryptoSwift
import Web3

extension WalletService {
    
    // per packet. 0.01 ETH
    public static var redPacketMinAmount: Decimal {
        return Decimal(0.01)
    }
    
    // per packet. 0.01 ETH
    public static var redPacketMinAmountInWei: BigUInt {
        return 10000000.gwei
    }
    
    public static var redPacketContractABIData: Data {
        let path = Bundle(for: WalletService.self).path(forResource: "redpacket", ofType: "json")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        return data
    }
    
    public static var redPacketContract: DynamicContract {
        let contractABIData = redPacketContractABIData
        return try! web3.eth.Contract(json: contractABIData, abiKey: nil, address: nil)
    }
    
    public static var redPacketContractByteCode: EthereumData {
        let contractByteCode: EthereumData = {
            let path = Bundle(for: WalletService.self).path(forResource: "redpacket", ofType: "bin")
            let bytesString = try! String(contentsOfFile: path!)
            return try! EthereumData(ethereumValue: bytesString.trimmingCharacters(in: .whitespacesAndNewlines))
        }()
        return contractByteCode
    }
    
    static func createContractInvocation(for redPacketProperty: RedPacketProperty) throws -> SolidityConstructorInvocation {
        let parameters: [ABIEncodable] = {
            let uuids = redPacketProperty.uuids
            let _hashes: [BigUInt] = uuids.map { uuid in
                let hash = SHA3(variant: .keccak256).calculate(for: uuid.bytes)
                print("\(uuid): \(hash.toHexString())")
                return BigUInt(hash)
            }
            let ifrandom: Bool = redPacketProperty.splitType == .random
            let duration = BigUInt(integerLiteral: 0)   // fallback to default 24h
            let seed = BigUInt.randomInteger(withMaximumWidth: 32)
            
            return [_hashes, ifrandom, duration, seed]
        }()
        
        guard let invocation = redPacketContract.deploy(byteCode: redPacketContractByteCode, parameters: parameters) else {
            throw Error.contractConstructFail
        }
        
        return invocation
    }
    
}

extension WalletService {
    
    public static func getTransactionCount(address: EthereumAddress, block: EthereumQuantityTag = .latest) -> Single<EthereumQuantity> {
        return Single.create { single in
            web3.eth.getTransactionCount(address: address, block: .latest) { response in
                switch response.status {
                case let .success(nonce):   single(.success(nonce))
                case let .failure(error):   single(.error(error))
                }
            }
            
            return Disposables.create { }
        }
    }
    
    public static func getContractAddress(transactionHash: EthereumData) -> Single<EthereumData> {
        return Single.create { single in
            web3.eth.getTransactionReceipt(transactionHash: transactionHash) { response in
                switch response.status {
                case let .success(receipt):
                    guard let address = receipt?.contractAddress else {
                        single(.error(Error.contractConstructFail))
                        return
                    }
                    single(.success(address))
                case let .failure(error):
                    // Pending block not return response
                    single(.error(Error.contractConstructReceiptResponsePending))
                }
            }
            
            return Disposables.create { }
        }
    }
    
    public static func getBalance(for address: String) -> Single<BigUInt> {
        return Single.create { single in
            do {
                let ethereumAddress = try EthereumAddress(hex: address, eip55: false)   // should EIP55 but compatibility first
                web3.eth.getBalance(address: ethereumAddress, block: .latest) { response in
                    switch response.status {
                    case .success(let result): single(.success(result.quantity))
                    case .failure(let error):  single(.error(error))
                    }
                }
            } catch {
                os_log("%{public}s[%{public}ld], %{public}s: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)

                single(.error(error))
            }

            return Disposables.create { }
        }
    }
    
    /// Deploy red packet contract
    ///
    /// Return deploy transaction hash
    /// - Parameter redPacketProperty: contract detail
    static func delopyRedPacket(for redPacketProperty: RedPacketProperty, nonce: EthereumQuantity) -> Single<EthereumData> {
        return Single.create { single in
            let cancelable = Disposables.create { }
            
            do {
                try WalletService.validate(redPacketProperty: redPacketProperty)
            } catch {
                single(.error(error))
                return cancelable
            }
            
            guard let walletModel = redPacketProperty.walletModel,
            let walletAddress = try? EthereumAddress(hex: walletModel.address, eip55: false),
            let hexPrivateKey = try? walletModel.hdWallet.privateKey().key.toHexString(),
            let privateKey = try? EthereumPrivateKey(hexPrivateKey: "0x" + hexPrivateKey) else {
                single(.error(Error.invalidWallet))
                return cancelable
            }
            
            var invocation: SolidityConstructorInvocation
            do {
                invocation = try createContractInvocation(for: redPacketProperty)
            } catch {
                single(.error(error))
                return cancelable
            }
            
            let _createContractTransaction: EthereumTransaction? = {
                let value = EthereumQuantity(quantity: redPacketProperty.amountInWei)
                let gas: EthereumQuantity = 3000000
                let gasPrice = EthereumQuantity(quantity: 1.gwei)
                return invocation.createTransaction(nonce: nonce, from: walletAddress, value: value, gas: gas, gasPrice: gasPrice)
            }()
            
            guard let createContractTransaction = _createContractTransaction,
            let signedCreateContractTransaction = try? createContractTransaction.sign(with: privateKey, chainId: chainID) else {
                single(.error(Error.contractConstructFail))
                return cancelable
            }
            
            web3.eth.sendRawTransaction(transaction: signedCreateContractTransaction) { response in
                switch response.status {
                case let .success(hash):    single(.success(hash))
                case let .failure(error):   single(.error(error))
                }
            }
            
            return cancelable
        }
    }
    
    static func checkAvailablity(for contractAddress: EthereumAddress) -> Single<(BigUInt, BigUInt)> {
        let contractABIData = WalletService.redPacketContractABIData
        let contract = try! web3.eth.Contract(json: contractABIData, abiKey: nil, address: contractAddress)
        let checkAvailabilityInvocation = contract["check_availability"]!()
        
        return Single.create { single in
            let cancelable = Disposables.create { }
            
            os_log("%{public}s[%{public}ld], %{public}s: checkAvailabilityInvocation.call", ((#file as NSString).lastPathComponent), #line, #function)
            checkAvailabilityInvocation.call { dict, error in

                guard let dict = dict,
                let balance = dict["balance"] as? BigUInt,
                let totalNumber = dict["total"] as? BigUInt,
                let claimedNumber = dict["claimed"] as? BigUInt else {
                    single(.error(Error.checkAvailabilityFail))
                    return
                }
                
                single(.success((balance, claimedNumber)))
            }
            
            return cancelable
        }
    }
    
    static func claim(for contractAddress: EthereumAddress, with uuid: String, from walletAddress: EthereumAddress, use privateKey: EthereumPrivateKey, nonce: EthereumQuantity) -> Single<BigUInt> {
        let contractABIData = WalletService.redPacketContractABIData
        let contract = try! web3.eth.Contract(json: contractABIData, abiKey: nil, address: contractAddress)
        let claimInvocation = contract["claim"]!(uuid)
        
        guard let claimTransaction = claimInvocation.createTransaction(nonce: nonce, from: walletAddress, value: 0, gas: 210000, gasPrice: EthereumQuantity(quantity: 1.gwei)) else {
            return Single.error(Error.invalidWallet)
        }
        
        guard let signedClaimTransaction = try? claimTransaction.sign(with: privateKey, chainId: chainID) else {
            return Single.error(Error.invalidWallet)
        }
        
        let transactionHash = Single<EthereumData>.create { single in
            let cancelable = Disposables.create { }
            web3.eth.sendRawTransaction(transaction: signedClaimTransaction) { response in
                switch response.status {
                case let .success(transactionHash):
                    os_log("%{public}s[%{public}ld], %{public}s: claim transactionHash %s", ((#file as NSString).lastPathComponent), #line, #function, transactionHash.hex())

                    single(.success(transactionHash))
                case let .failure(error):
                    single(.error(Error.claimTransactionFail))
                }
            }

            return cancelable
        }
        
        return transactionHash.flatMap { transactionHash -> Single<BigUInt> in
            return Single.create { single in
                web3.eth.getTransactionReceipt(transactionHash: transactionHash) { response in
                    guard let receipt = response.result,
                    let logs = receipt?.logs else {
                        single(.error(Error.claimTransactionReceiptResponsePending))
                        return
                    }
                    
                    guard let successEvent = (contract.events.filter { $0.name == "ClaimSuccess" }.first) else {
                        assertionFailure()
                        single(.error(Error.claimTransactionReceiptResponsePending))
                        return
                    }
                    
                    var claimed: BigUInt? = nil
                    for log in logs {
                        if let result = try? ABI.decodeLog(event: successEvent, from: log),
                        let claimedValue = result["claimed_value"] as? BigUInt {
                            claimed = claimedValue
                            break
                        } else {
                            continue
                        }
                    }
                    
                    if let claimed = claimed {
                        single(.success(claimed))
                    } else {
                        single(.error(Error.claimTransactionReceiptResponsePending))
                    }
                }
                
                return Disposables.create { }
            }
            .retryWhen({ error -> Observable<Int> in
                return error.enumerated().flatMap({ index, element -> Observable<Int> in
                    os_log("%{public}s[%{public}ld], %{public}s: claim receipt check retry %s times", ((#file as NSString).lastPathComponent), #line, #function, String(index + 1))
                    // retry 6 times
                    guard index < 6 else {
                        return Observable.error(element)
                    }
                    // retry every 10.0 sec
                    return Observable.timer(10.0, scheduler: MainScheduler.instance)
                })
            })
        }
    }

}

extension WalletService {
    
    static func validate(redPacketProperty: RedPacketProperty) throws {
        guard let walletModel = redPacketProperty.walletModel,
        let _ = try? walletModel.hdWallet.privateKey() else {
            throw Error.invalidWallet
        }
        
        guard redPacketProperty.amount >= redPacketMinAmount else {
            throw Error.invalidAmount
        }
        
        guard let _ = redPacketProperty.sender else {
            throw Error.invalidSender
        }
        
        let recipients = redPacketProperty.contactInfos.filter { contractInfo in
            let keys = contractInfo.keys.filter { $0.hasPublicKey }
            return !keys.isEmpty
        }
        guard !recipients.isEmpty else {
            throw Error.invalidRecipients
        }
    }
}

extension WalletService {
    enum Error: Swift.Error {
        case invalidWallet
        case invalidAmount
        case invalidSender
        case invalidRecipients

        case contractConstructFail
        case contractConstructReceiptResponsePending
        case contractAddressInvalid
        
        case checkAvailabilityFail
        case claimTransactionFail
        case claimTransactionReceiptResponsePending
        
        case insufficientGas
    }
}

extension WalletService.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidWallet: return "Invalid Wallet"
        case .invalidAmount: return "Red Packet Amount Invalid"
        case .invalidSender: return "Red Packet Sender Invalid"
        case .invalidRecipients: return "Red Packet Recipients Invalid"
            
        case .contractConstructFail: return "Red Packet Construction Fail"
        case .contractConstructReceiptResponsePending: return "Red Packet Receipt Lookup Fail"
        case .contractAddressInvalid: return "Red Packet Not Found"
            
        case .checkAvailabilityFail: return "Red Packet Check Fail"
        case .claimTransactionFail: return "Red Packet Claim Fail"
        case .claimTransactionReceiptResponsePending: return "Red Packet Claim Lookup Fail"
            
        case .insufficientGas: return "Insufficient Gas"
        }
    }
}
