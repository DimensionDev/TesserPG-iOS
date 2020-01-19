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
    
    /// Get nonce for wallet
    /// - Parameters:
    ///   - address: ethereum wallet address
    ///   - block: block tag. default is .latest
    public static func getTransactionCount(address: EthereumAddress, block: EthereumQuantityTag = .latest, web3: Web3) -> Single<EthereumQuantity> {
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
    
    public static func getContractAddress(transactionHash: EthereumData, web3: Web3) -> Single<EthereumData> {
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
    
    public static func getBalance(for address: String, web3: Web3) -> Single<BigUInt> {
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
    
    public static func getERC20TokenBalance(forWallet address: String, ofContract contract: String, web3: Web3) -> Single<BigUInt> {
        guard let contractAddress = try? EthereumAddress(hex: contract, eip55: false) else {
            return Single.error(Error.contractAddressInvalid)
        }
        let erc20Contract = GenericERC20Contract(address: contractAddress, eth: web3.eth)
        
        guard let ethereumAddress = try? EthereumAddress(hex: address, eip55: false) else {
            return Single.error(Error.contractAddressInvalid)
        }
        
        return Single.create { single -> Disposable in
            erc20Contract.balanceOf(address: ethereumAddress).call(block: .latest) { dict, error in
                if let error = error {
                    single(.error(error))
                    os_log("%{public}s[%{public}ld], %{public}s: error: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                } else {
                    guard let balance = dict?["_balance"] as? BigUInt else {
                        single(.error(Error.invalidAmount))
                        return
                    }
                    single(.success(balance))
                }
            }
            
            return Disposables.create { }
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
        case checkAvailabilityEmpty
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
        case .checkAvailabilityEmpty: return "All Red Packets Have Been Claimed"
        case .claimTransactionFail: return "Red Packet Claim Fail"
        case .claimTransactionReceiptResponsePending: return "Red Packet Claim Lookup Fail"
            
        case .insufficientGas: return "Insufficient Gas"
        }
    }
}
