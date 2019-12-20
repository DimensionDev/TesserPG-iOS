//
//  RedPacketService+RedPacket.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-18.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import Foundation
import RealmSwift
import RxSwift
import RxCocoa
import Web3
import CryptoSwift

extension RedPacketService {
    
    static func claim(for redPacket: RedPacket, use walletModel: WalletModel, nonce: EthereumQuantity) -> Single<TransactionHash> {
        os_log("%{public}s[%{public}ld], %{public}s: prepare to claim red packet - %s", ((#file as NSString).lastPathComponent), #line, #function, redPacket.red_packet_id ?? "nil")

        // Only for contract v1
        assert(redPacket.contract_version == 1)
        
        // Only normal || incoming statuc red packet can process `claim` on the contract
        guard redPacket.status == .normal || redPacket.status == .incoming else {
            return Single.error(Error.internal("cannot claim unacceptable status red packet"))
        }
        
        // Init wallet
        let walletAddress: EthereumAddress
        let walletPrivateKey: EthereumPrivateKey
        do {
            let meta = try RedPacketService.prepareWalletMeta(from: walletModel)
            walletAddress = meta.walletAddress
            walletPrivateKey = meta.walletPrivateKey
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
        
        let contract: DynamicContract
        do {
            contract = try RedPacketService.prepareContract(for: contractAddressString, in: web3)
        } catch {
            return Single.error(Error.internal(error.localizedDescription))
        }
        
        // Prepare parameters
        guard let redPacketIDHex = redPacket.red_packet_id,
        let redPacketID = BigUInt(hexString: redPacketIDHex) else {
            return Single.error(Error.internal("cannot get red packet id to claim"))
        }
        let recipient = walletAddress
        let validation: BigUInt
        do {
            let validationBytes = SHA3(variant: .keccak256).calculate(for: try recipient.makeBytes())
            validation = BigUInt(validationBytes)
        } catch {
            return Single.error(Error.internal("cannot calculate validation for recipient address"))
        }
        
        guard let claimCall = contract["claim"] else {
            return Single.error(Error.internal("cannot construct call to claim red packet"))
        }
        
        let id = redPacket.id
        
        return RedPacketService.checkAvailability(for: redPacket)
            .retry(3)
            .flatMap { availability -> Single<TransactionHash> in
                os_log("%{public}s[%{public}ld], %{public}s: check availability %s/%s", ((#file as NSString).lastPathComponent), #line, #function, String(availability.claimed), String(availability.total))
                
                let realm: Realm
                do {
                    realm = try RedPacketService.realm()
                } catch {
                    return Single.error(Error.internal(error.localizedDescription))
                }
                guard let redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
                    return Single.error(Error.internal("cannot reslove red packet to check availablity"))
                }
            
                guard availability.claimed < availability.total, availability.claimed < redPacket.uuids.count else {
                    return Single.error(Error.noAvailableShareForClaim)
                }
                
                let password = redPacket.uuids[availability.claimed]
                let claimInvocation = claimCall(redPacketID, password, recipient, validation)
                let gasLimit = EthereumQuantity(integerLiteral: 1000000)
                let gasPrice = EthereumQuantity(quantity: 10.gwei)
                guard let claimTransaction = claimInvocation.createTransaction(nonce: nonce, from: walletAddress, value: 0, gas: gasLimit, gasPrice: gasPrice) else {
                    return Single.error(Error.internal("cannot construct transaction to claim red packet"))
                }
                let signedClaimTransaction: EthereumSignedTransaction
                do {
                    signedClaimTransaction = try claimTransaction.sign(with: walletPrivateKey, chainId: chainID)
                } catch {
                    return Single.error(Error.internal(error.localizedDescription))
                }
                
                return Single.create { single -> Disposable in
                    os_log("%{public}s[%{public}ld], %{public}s: claim red packet - %s", ((#file as NSString).lastPathComponent), #line, #function, redPacketIDHex)

                    web3.eth.sendRawTransaction(transaction: signedClaimTransaction) { response in
                        switch response.status {
                        case let .success(transactionHash):
                            single(.success(transactionHash))
                        case let .failure(error):
                            single(.error(error))
                        }
                    }
                    
                    return Disposables.create { }
                }
            }
    }
    
}

extension RedPacketService {
    
    struct ClaimSuccess {
        let id: String
        let claimer: String
        let claimed_value: BigUInt
    }
    
}
