//
//  RedPacketService+Refund.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-30.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import Foundation
import RealmSwift
import RxSwift
import RxCocoa
import BigInt
import Web3

extension RedPacketService {
    
    static func refund(for redPacket: RedPacket, use walletModel: WalletModel, nonce: EthereumQuantity) -> Single<TransactionHash> {
        os_log("%{public}s[%{public}ld], %{public}s: prepare to claim red packet - %s", ((#file as NSString).lastPathComponent), #line, #function, redPacket.red_packet_id ?? "nil")

        // Only for contract v1
        assert(redPacket.contract_version == 1)
        
        do {
            try checkNetwork(for: redPacket)
        } catch {
            return Single.error(error)
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
        
        let id = redPacket.id

        return RedPacketService.shared.checkAvailability(for: redPacket)
            .retry(3)
            .asSingle()
            .flatMap { availability -> Single<TransactionHash> in
                os_log("%{public}s[%{public}ld], %{public}s: check availability %s/%s", ((#file as NSString).lastPathComponent), #line, #function, String(availability.claimed), String(availability.total))
                
                // only expired red packet could refund
                guard availability.expired else {
                    return Single.error(Error.refundBeforeExipired)
                }
                
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
                
//                let password = redPacket.uuids[availability.claimed]
//                let claimInvocation = claimCall(redPacketID, password, recipient, validation)
//                let gasLimit = EthereumQuantity(integerLiteral: 1000000)
//                let gasPrice = EthereumQuantity(quantity: 10.gwei)
//                guard let claimTransaction = claimInvocation.createTransaction(nonce: nonce, from: walletAddress, value: 0, gas: gasLimit, gasPrice: gasPrice) else {
//                    return Single.error(Error.internal("cannot construct transaction to claim red packet"))
//                }
//                let signedClaimTransaction: EthereumSignedTransaction
//                do {
//                    signedClaimTransaction = try claimTransaction.sign(with: walletPrivateKey, chainId: chainID)
//                } catch {
//                    return Single.error(Error.internal(error.localizedDescription))
//                }
                return Single.error(Error.internal("TBD"))
                
//                return Single.create { single -> Disposable in
//                    os_log("%{public}s[%{public}ld], %{public}s: claim red packet - %s", ((#file as NSString).lastPathComponent), #line, #function, redPacketIDHex)
//
//                    web3.eth.sendRawTransaction(transaction: signedClaimTransaction) { response in
//                        switch response.status {
//                        case let .success(transactionHash):
//                            single(.success(transactionHash))
//                        case let .failure(error):
//                            single(.error(error))
//                        }
//                    }
//
//                    return Disposables.create { }
//                }
        }
        
    }

    // static func refund(for redPacket: RedPacket) -> Single<RefundSuccess> {
    //     return Single.error(Error.internal("TBD"))
    // }
    
}

extension RedPacketService {
    
    struct RefundSuccess {
        let id: String
        let remaining_balance: BigUInt
    }
}
