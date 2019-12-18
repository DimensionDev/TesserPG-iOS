//
//  RedPacketService+Web3.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-18.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import Foundation
import RxSwift
import CryptoSwift
import Web3

typealias TransactionHash = EthereumData

extension RedPacketService {
    
    /// Send create red packet (V1) transaction and return transaction hash
    /// - Parameters:
    ///   - redPacket: initial status red packet model
    ///   - walletModel: sender wallet
    ///   - nonce: nonce for wallet
    static func create(for redPacket: RedPacket, use walletModel: WalletModel, nonce: EthereumQuantity) -> Single<TransactionHash> {
        // Only for contract v1
        assert(redPacket.contract_version == 1)

        // Only initial red packet can process `create` on the contract
        guard redPacket.status == .initial else {
            assertionFailure()
            return Single.error(Error.internal("cannot create red packet repeatedly"))
        }
        
        // Init wallet
        guard redPacket.sender_address == walletModel.address else {
            assertionFailure()
            return Single.error(Error.internal("use mismatched wallet to sign"))
        }
        
        let walletAddress: EthereumAddress
        let walletPrivateKey: EthereumPrivateKey
        do {
            walletAddress = try EthereumAddress(hex: walletModel.address, eip55: false)
            let privateKeyHex = try walletModel.hdWallet.privateKey().key.toHexString()
            walletPrivateKey = try EthereumPrivateKey(hexPrivateKey: "0x" + privateKeyHex)
        } catch {
            return Single.error(Error.internal(error.localizedDescription))
        }

        // Init web3
        let web3 = WalletService.web3
        let chainID = WalletService.chainID
        
        // Init contract
        guard let contractAddressString = redPacket.contract_address else {
            return Single.error(Error.internal("cannot get red packet contract address"))
        }
        
        let contractAddress: EthereumAddress
        let contract: DynamicContract
        do {
            let contractABIData = RedPacketService.redPacketContractABIData
            contractAddress = try EthereumAddress(hex: contractAddressString, eip55: false)
            contract = try web3.eth.Contract(json: contractABIData, abiKey: nil, address: contractAddress)
        } catch {
            return Single.error(Error.internal(error.localizedDescription))
        }
        
        // Prepare parameters
        let uuids = Array(redPacket.uuids)
        let hashes:[BigUInt] = uuids.map { uuid in
            let hash = SHA3(variant: .keccak256).calculate(for: uuid.bytes)
            return BigUInt(hash)
        }
        let ifRandom = redPacket.is_random
        let duration = redPacket.duration
        let seed = BigUInt.randomInteger(withMaximumWidth: 32)
        let message = redPacket.send_message
        let name = redPacket.sender_name
        
        let value = EthereumQuantity(quantity: redPacket.send_total)
        
        // Init transaction to create red packet
        guard let createCall = contract["create_red_packet"] else {
            return Single.error(Error.internal("cannot construct call to send red packet"))
        }
        
        let gasLimit = EthereumQuantity(integerLiteral: 1000000)
        let gasPrice = EthereumQuantity(quantity: 10.gwei)
        
        let createInvocation = createCall(hashes, ifRandom, duration, seed, message, name)
        guard let createTransaction = createInvocation.createTransaction(nonce: nonce, from: walletAddress, value: value, gas: gasLimit, gasPrice: gasPrice) else {
            return Single.error(Error.internal("cannot construct transaction to send red packet"))
        }
        
        let signedCreateTransaction: EthereumSignedTransaction
        do {
            signedCreateTransaction = try createTransaction.sign(with: walletPrivateKey, chainId: chainID)
        } catch {
            return Single.error(Error.internal(error.localizedDescription))
        }
        
        let transactionHash = Single<TransactionHash>.create { single -> Disposable in
            web3.eth.sendRawTransaction(transaction: signedCreateTransaction) { response in
                switch response.status {
                case let .success(transactionHash):
                    single(.success(transactionHash))
                case let .failure(error):
                    single(.error(error))
                }
            }
            
            return Disposables.create { }
        }
        
        return transactionHash
    }
    
}

extension RedPacketService {
    
    enum Error: Swift.Error {
        case `internal`(String)
    }
    
}

extension RedPacketService.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .internal(message):     return "Internal error: \(message)\nPlease try again"
        }
    }
}
