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
    
    private static func refund(for redPacket: RedPacket, use walletModel: WalletModel, nonce: EthereumQuantity) -> Single<TransactionHash> {
        os_log("%{public}s[%{public}ld], %{public}s: prepare to refund red packet - %s", ((#file as NSString).lastPathComponent), #line, #function, redPacket.red_packet_id ?? "nil")

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
        
        // Init web3
        let web3 = WalletService.web3
        let chainID = WalletService.chainID
        
        // Init contract
        let contract: DynamicContract
        do {
            contract = try RedPacketService.prepareContract(for: redPacket.contract_address, in: web3)
        } catch {
            return Single.error(Error.internal(error.localizedDescription))
        }
        
        // Prepare parameters
        guard let redPacketIDHex = redPacket.red_packet_id,
            let redPacketID = BigUInt(hexString: redPacketIDHex) else {
                return Single.error(Error.internal("cannot get red packet id to claim"))
        }
        
        guard let refundCall = contract["refund"] else {
            return Single.error(Error.internal("cannot construct call to claim red packet"))
        }
        
        let id = redPacket.id
        
        return RedPacketService.shared.checkAvailability(for: redPacket)
            .retry(3)
            .asSingle()
            .flatMap { availability -> Single<TransactionHash> in
                os_log("%{public}s[%{public}ld], %{public}s: check availability %s/%s, isExpired %s", ((#file as NSString).lastPathComponent), #line, #function, String(availability.claimed), String(availability.total), String(availability.expired))

                let realm: Realm
                do {
                    realm = try RedPacketService.realm()
                } catch {
                    return Single.error(Error.internal(error.localizedDescription))
                }
                guard let redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
                    return Single.error(Error.internal("cannot reslove red packet to check availablity"))
                }
                
                // only expired red packet could refund
                guard redPacket.status == .expired else {
                    os_log("%{public}s[%{public}ld], %{public}s: refundBeforeExpired. Current status: %s", ((#file as NSString).lastPathComponent), #line, #function, redPacket.status.rawValue)
                    return Single.error(Error.refundBeforeExpired)
                }
                
                // TODO: remove it if not require it
                guard availability.claimed < availability.total else {
                    return Single.error(Error.noAvailableShareForRefund)
                }
                
                let refundInvocation = refundCall(redPacketID)
                let gasLimit = EthereumQuantity(integerLiteral: 1000000)
                let gasPrice = EthereumQuantity(quantity: 10.gwei)
                guard let refundTransaction = refundInvocation.createTransaction(nonce: nonce, from: walletAddress, value: 0, gas: gasLimit, gasPrice: gasPrice) else {
                    return Single.error(Error.internal("cannot construct transaction to refund red packet"))
                }
                let signedRefundTransaction: EthereumSignedTransaction
                do {
                    signedRefundTransaction = try refundTransaction.sign(with: walletPrivateKey, chainId: chainID)
                } catch {
                    return Single.error(Error.internal(error.localizedDescription))
                }
                
                return Single.create { single -> Disposable in
                    os_log("%{public}s[%{public}ld], %{public}s: refund red packet - %s", ((#file as NSString).lastPathComponent), #line, #function, redPacketIDHex)
                    
                    web3.eth.sendRawTransaction(transaction: signedRefundTransaction) { response in
                        switch response.status {
                        case let .success(transactionHash):
                            single(.success(transactionHash))
                        case let .failure(error):
                            if let rpcError = error as? RPCResponse<EthereumData>.Error {
                                single(.error(Error.internal(rpcError.message)))
                            } else {
                                single(.error(error))
                            }
                        }
                    }
                    
                    return Disposables.create { }
                }
            }   // end flatMap { availability -> Single<TransactionHash> in … }
        
    }

    private static func refundResult(for redPacket: RedPacket) -> Single<RefundSuccess> {
        os_log("%{public}s[%{public}ld], %{public}s: refund claim result for red packet - %s", ((#file as NSString).lastPathComponent), #line, #function, redPacket.red_packet_id ?? "nil")
        
        // Only for contract v1
        assert(redPacket.contract_version == 1)
        
        do {
            try checkNetwork(for: redPacket)
        } catch {
            return Single.error(error)
        }
        
        guard let refundTransactionHashHex = redPacket.refund_transaction_hash else {
            return Single.error(Error.internal("cannot read refund transaction hash"))
        }
        
        let refundTransactionHash: TransactionHash
        do {
            let ethernumValue = EthereumValue(stringLiteral: refundTransactionHashHex)
            refundTransactionHash = try EthereumData(ethereumValue: ethernumValue)
        } catch {
            return Single.error(Error.internal("cannot read refund transaction hash"))
        }
        
        // Init web3
        let web3 = WalletService.web3
        
        // Init contract
        let contract: DynamicContract
        do {
            contract = try RedPacketService.prepareContract(for: redPacket.contract_address, in: web3)
        } catch {
            return Single.error(Error.internal(error.localizedDescription))
        }
        
        // Prepare decoder
        guard let refundSuccessEvent = (contract.events.filter { $0.name == "RefundSuccess" }.first) else {
            return Single.error(Error.internal("cannot read refund event from contract"))
        }
        
        return Single<RefundSuccess>.create { single -> Disposable in
            web3.eth.getTransactionReceipt(transactionHash: refundTransactionHash) { response in
                switch response.status {
                case let .success(receipt):
                    // Receipt return status => success
                    // Should read RefundSuccess log otherwise throw refundFail error
                    guard let status = receipt?.status, status.quantity == 1 else {
                        single(.error(Error.refundFail))
                        return
                    }
                    
                    guard let logs = receipt?.logs else {
                        single(.error(Error.refundFail))
                        return
                    }
                    
                    var resultDict: [String: Any]?
                    for log in logs {
                        guard let result = try? ABI.decodeLog(event: refundSuccessEvent, from: log) else {
                            continue
                        }
                        
                        resultDict = result
                        break
                    }
                    
                    guard let dict = resultDict,
                    let idBytes = dict["id"] as? Data,
                    let remainingBalance = dict["remaining_balance"] as? BigUInt else {
                        single(.error(Error.refundFail))
                        return
                    }
                    
                    let event = RefundSuccess(id: idBytes.toHexString(),
                                              remaining_balance: remainingBalance)
                    single(.success(event))
                case let .failure(error):
                    if let rpcError = error as? RPCResponse<EthereumTransactionReceiptObject?>.Error {
                        single(.error(Error.internal(rpcError.message)))
                    } else {
                        single(.error(error))
                    }
                }
            }
            
            return Disposables.create { }
        }
        .retryWhen { error -> Observable<Int> in
            return error.enumerated().flatMap { index, element -> Observable<Int> in
                // Only retry when empty response (response should not empty when block mined
                guard case Web3Response<EthereumTransactionReceiptObject?>.Error.emptyResponse = element else {
                    return Observable.error(element)
                }
                
                os_log("%{public}s[%{public}ld], %{public}s: fetch refund result fail. Retry %s times", ((#file as NSString).lastPathComponent), #line, #function, String(index + 1))
                
                // max retry 6 times
                guard index < 6 else {
                    return Observable.error(element)
                }
                
                // retry every 10 sec
                return Observable.timer(.seconds(10), scheduler: MainScheduler.instance)
            }
        }
    }
    
}

extension RedPacketService {
    
    func refund(for redPacket: RedPacket, use walletModel: WalletModel, nonce: EthereumQuantity) -> Observable<TransactionHash> {
        let id = redPacket.id
        
        guard let observable = refundQueue[id] else {
            let single = RedPacketService.refund(for: redPacket, use: walletModel, nonce: nonce)
            
            let shared = single.asObservable()
                .flatMapLatest { transactionHash -> Observable<TransactionHash> in
                    do {
                        // red packet refund transaction success
                        // set status to .refund_pending
                        let realm = try RedPacketService.realm()
                        guard let redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
                            return Single.error(Error.internal("cannot reslove red packet to check availablity")).asObservable()
                        }
                        try realm.write {
                            redPacket.refund_transaction_hash = transactionHash.hex()
                            redPacket.status = .refund_pending
                        }
                        
                        return Single.just(transactionHash).asObservable()
                    } catch {
                        return Single.error(error).asObservable()
                    }
                }
                .share()
            
            refundQueue[id] = shared
            
            // Subscribe in service to prevent task canceled
            shared
                .asSingle()
                .do(afterSuccess: { _ in
                    os_log("%{public}s[%{public}ld], %{public}s: afterSuccess refund", ((#file as NSString).lastPathComponent), #line, #function)
                    self.refundQueue[id] = nil
                }, afterError: { _ in
                    os_log("%{public}s[%{public}ld], %{public}s: afterError refund", ((#file as NSString).lastPathComponent), #line, #function)
                    self.refundQueue[id] = nil
                })
                .subscribe()
                .disposed(by: disposeBag)
            
            return shared
        }
        
        os_log("%{public}s[%{public}ld], %{public}s: use refund in queue", ((#file as NSString).lastPathComponent), #line, #function)
        return observable
    }
    
    func refundResult(for redPacket: RedPacket) -> Observable<RefundSuccess> {
        let id = redPacket.id
        
        guard let observable = refundResultQueue[id] else {
            let single = RedPacketService.refundResult(for: redPacket)
            
            let shared = single.asObservable()
                .share()
            
            refundResultQueue[id] = shared
            
            // Subscribe in service to prevent task canceled
            shared
                .asSingle()
                .do(afterSuccess: { _ in
                    os_log("%{public}s[%{public}ld], %{public}s: afterSuccess refundResult", ((#file as NSString).lastPathComponent), #line, #function)
                    self.refundResultQueue[id] = nil
                }, afterError: { _ in
                    os_log("%{public}s[%{public}ld], %{public}s: afterError refundResult", ((#file as NSString).lastPathComponent), #line, #function)
                    self.refundResultQueue[id] = nil
                })
                .subscribe()
                .disposed(by: disposeBag)
            
            return shared
        }
        
        os_log("%{public}s[%{public}ld], %{public}s: use refundResult in queue", ((#file as NSString).lastPathComponent), #line, #function)
        return observable
    }
    
    func updateRefundResult(for redPacket: RedPacket) -> Observable<RefundSuccess> {
        let id = redPacket.id
        
        guard let observable = updateRefundResultQueue[id] else {
            // read red packet object from disk to prevent refund_transaction_hash write to disk but not updated issue
            let realm: Realm
            do {
                realm = try RedPacketService.realm()
            } catch {
                return Single.error(Error.internal(error.localizedDescription)).asObservable()
            }
            guard let redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
                return Single.error(Error.internal("cannot reslove red packet to check availablity")).asObservable()
            }
            
            let single = self.refundResult(for: redPacket)
            
            let shared = single.asObservable()
                .share()
            
            updateRefundResultQueue[id] = shared

            // Subscribe in service to prevent task canceled
            shared
                .asSingle()
                .do(onSuccess: { refundSuccess in
                    do {
                        let realm = try RedPacketService.realm()
                        guard let redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
                            return
                        }
                        
                        guard redPacket.status == .refund_pending else {
                            os_log("%{public}s[%{public}ld], %{public}s: discard change due to red packet status already %s.", ((#file as NSString).lastPathComponent), #line, #function, redPacket.status.rawValue)
                            return
                        }
                        
                        os_log("%{public}s[%{public}ld], %{public}s: change red packet status to .refunded", ((#file as NSString).lastPathComponent), #line, #function)
                        try realm.write {
                            redPacket.refund_amount = refundSuccess.remaining_balance
                            redPacket.status = .refunded
                        }
                    } catch {
                        os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    }

                }, afterSuccess: { _ in
                    os_log("%{public}s[%{public}ld], %{public}s: afterSuccess updateRefundResult", ((#file as NSString).lastPathComponent), #line, #function)
                    self.updateRefundResultQueue[id] = nil
                }, onError: { error in
                    guard case RedPacketService.Error.refundFail = error else {
                        return
                    }
                    
                    do {
                        let realm = try RedPacketService.realm()
                        guard let redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
                            return
                        }
                        
                        guard redPacket.status == .refund_pending else {
                            os_log("%{public}s[%{public}ld], %{public}s: discard change due to red packet status already %s. not .refund_pending", ((#file as NSString).lastPathComponent), #line, #function, redPacket.status.rawValue)
                            return
                        }
                        
                        os_log("%{public}s[%{public}ld], %{public}s: rollback red packet status to expired", ((#file as NSString).lastPathComponent), #line, #function)
                        try realm.write {
                            redPacket.refund_transaction_hash = nil
                            redPacket.status = .expired
                        }
                    } catch {
                        os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    }

                }, afterError: { _ in
                    os_log("%{public}s[%{public}ld], %{public}s: afterError updateRefundResult", ((#file as NSString).lastPathComponent), #line, #function)
                    self.updateRefundResultQueue[id] = nil
                })
                .subscribe()
                .disposed(by: disposeBag)
            
            return shared
        }
        
        os_log("%{public}s[%{public}ld], %{public}s: use updateRefund in queue", ((#file as NSString).lastPathComponent), #line, #function)
        return observable
    }

}

extension RedPacketService {
    
    struct RefundSuccess {
        let id: String
        let remaining_balance: BigUInt
    }
}
