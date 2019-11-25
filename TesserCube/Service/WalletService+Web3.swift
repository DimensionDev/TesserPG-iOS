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
    
    public static var redPacketMinAmount: Decimal {
        return Decimal(0.001)
    }
    
    public static var redPacketContract: DynamicContract {
        let contractABIData: Data = {
            let path = Bundle(for: WalletService.self).path(forResource: "redpacket", ofType: "json")
            let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
            return data
        }()
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
            let expirationTime: BigUInt = {
                let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
                return BigUInt(nextWeek.timeIntervalSince1970)
            }()
            
            return [_hashes, ifrandom, expirationTime]
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
        
        case insufficientGas
    }
}
