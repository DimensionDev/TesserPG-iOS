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
    
    private static func claim(for redPacket: RedPacket, use walletModel: WalletModel, nonce: EthereumQuantity) -> Single<TransactionHash> {
        os_log("%{public}s[%{public}ld], %{public}s: prepare to claim red packet - %s", ((#file as NSString).lastPathComponent), #line, #function, redPacket.red_packet_id ?? "nil")

        // Only for contract v1
        assert(redPacket.contract_version == 1)
        
        do {
            try checkNetwork(for: redPacket)
        } catch {
            return Single.error(error)
        }
        
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
        
        return RedPacketService.shared.checkAvailability(for: redPacket)
            .retry(3)
            .asSingle()
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
    
    private static func claimResult(for redPacket: RedPacket) -> Single<ClaimSuccess> {
        // Only for contract v1
        assert(redPacket.contract_version == 1)
        
        do {
            try checkNetwork(for: redPacket)
        } catch {
            return Single.error(error)
        }
        
        guard let claimTransactionHashHex = redPacket.claim_transaction_hash else {
            return Single.error(Error.internal("cannot read claim transaction hash"))
        }
        
        let claimTransactionHash: TransactionHash
        do {
            let ethernumValue = EthereumValue(stringLiteral: claimTransactionHashHex)
            claimTransactionHash = try EthereumData(ethereumValue: ethernumValue)
        } catch {
            return Single.error(Error.internal("cannot read claim transaction hash"))
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
        guard let claimSuccessEvent = (contract.events.filter { $0.name == "ClaimSuccess" }.first) else {
            return Single.error(Error.internal("cannot read claim event from contract"))
        }
        
        return Single<ClaimSuccess>.create { single -> Disposable in
            web3.eth.getTransactionReceipt(transactionHash: claimTransactionHash) { response in
                switch response.status {
                case let .success(receipt):
                    // Receipt return status => success
                    // Should read ClaimSuccess log otherwise throw claimFail error
                    guard let status = receipt?.status, status.quantity == 1 else {
                        single(.error(Error.claimFail))
                        return
                    }
                    
                    guard let logs = receipt?.logs else {
                        single(.error(Error.claimFail))
                        return
                    }
                    
                    var resultDict: [String: Any]?
                    for log in logs {
                        guard let result = try? ABI.decodeLog(event: claimSuccessEvent, from: log) else {
                            continue
                        }
                        
                        resultDict = result
                        break
                    }
                    
                    guard let dict = resultDict,
                    let idBytes = dict["id"] as? Data,
                    let claimer = dict["claimer"] as? EthereumAddress,
                    let claimedValue = dict["claimed_value"] as? BigUInt else {
                        single(.error(Error.claimFail))
                        return
                    }
                    
                    let event = ClaimSuccess(id: idBytes.toHexString(),
                                             claimer: claimer.hex(eip55: true),
                                             claimed_value: claimedValue)
                    single(.success(event))
                    
                case let .failure(error):
                    single(.error(error))
                }
            }   // end web3
            
            return Disposables.create { }
        }
        .retryWhen { error -> Observable<Int> in
            return error.enumerated().flatMap { index, element -> Observable<Int> in
                // Only retry when empty response (response should not empty when block mined
                guard case Web3Response<EthereumTransactionReceiptObject?>.Error.emptyResponse = element else {
                    return Observable.error(element)
                }
                
                os_log("%{public}s[%{public}ld], %{public}s: fetch claim result fail. Retry %s times", ((#file as NSString).lastPathComponent), #line, #function, String(index + 1))
                
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
    
    // Shared Observable sequeue from Single<TransactionHash>
    func claim(for redPacket: RedPacket, use walletModel: WalletModel, nonce: EthereumQuantity) -> Observable<TransactionHash> {
        let id = redPacket.id
        
        guard let observable = claimQueue[id] else {
            let single = RedPacketService.claim(for: redPacket, use: walletModel, nonce: nonce)
            
            let shared = single.asObservable()
                .flatMapLatest { transactionHash -> Observable<TransactionHash> in
                    do {
                        // red packet claim transaction success
                        // set status to .claim_pending
                        let realm = try RedPacketService.realm()
                        guard let redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
                            return Single.error(Error.internal("cannot reslove red packet to check availablity")).asObservable()
                        }
                        try realm.write {
                            redPacket.claim_transaction_hash = transactionHash.hex()
                            redPacket.status = .claim_pending
                            redPacket.claim_address = walletModel.address
                        }
                        
                        return Single.just(transactionHash).asObservable()
                    } catch {
                        return Single.error(error).asObservable()
                    }
                }
                .share()
            
            // Subscribe in service to prevent task canceled
            shared
                .do(afterCompleted: {
                    os_log("%{public}s[%{public}ld], %{public}s: afterCompleted claim", ((#file as NSString).lastPathComponent), #line, #function)
                    self.claimQueue[id] = nil
                })
                .subscribe()
                .disposed(by: disposeBag)
            
            claimQueue[id] = shared
            return shared
        }
        
        os_log("%{public}s[%{public}ld], %{public}s: use claim in queue", ((#file as NSString).lastPathComponent), #line, #function)
        return observable
    }
    
    private func claimResult(for redPacket: RedPacket) -> Observable<ClaimSuccess> {
        let id = redPacket.id
        
        guard let observable = claimResultQueue[id] else {
            let single = RedPacketService.claimResult(for: redPacket)
            
            let shared = single.asObservable()
                .share()
            
            // Subscribe in service to prevent task canceled
            shared
                .do(afterCompleted: {
                    os_log("%{public}s[%{public}ld], %{public}s: afterCompleted claimResult", ((#file as NSString).lastPathComponent), #line, #function)
                    self.claimResultQueue[id] = nil
                })
                .subscribe()
                .disposed(by: disposeBag)
            
            claimResultQueue[id] = shared
            return shared
        }
        
        os_log("%{public}s[%{public}ld], %{public}s: use claimResult in queue", ((#file as NSString).lastPathComponent), #line, #function)
        return observable
    }

    func updateClaimResult(for redPacket: RedPacket) -> Observable<ClaimSuccess> {
        os_log("%{public}s[%{public}ld], %{public}s: update claim result for red packet - %s", ((#file as NSString).lastPathComponent), #line, #function, redPacket.red_packet_id ?? "nil")

        let id = redPacket.id
        
        guard let observable = updateClaimResultQueue[id] else {
            let single = self.claimResult(for: redPacket)
            
            let shared = single.asObservable()
                .share()
            
            // Subscribe in service to prevent task canceled
            shared
                .do(onNext: { claimSuccess in     // before subscribe onNext
                    do {
                        let realm = try RedPacketService.realm()
                        guard let redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
                            return
                        }
                        
                        guard redPacket.status == .claim_pending else {
                            os_log("%{public}s[%{public}ld], %{public}s: discard change due to red packet status already %s.", ((#file as NSString).lastPathComponent), #line, #function, redPacket.status.rawValue)
                            return
                        }
                        
                        os_log("%{public}s[%{public}ld], %{public}s: change red packet status to .claimed", ((#file as NSString).lastPathComponent), #line, #function)
                        try realm.write {
                            redPacket.claim_amount = claimSuccess.claimed_value
                            redPacket.status = .claimed
                        }
                    } catch {
                        os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    }
                    
                }, onError: { error in     // before subscribe onError
                    do {
                        let realm = try RedPacketService.realm()
                        guard let redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
                            return
                        }
                        
                        guard redPacket.status == .claim_pending else {
                            os_log("%{public}s[%{public}ld], %{public}s: discard change due to red packet status already %s. not .claim_pending", ((#file as NSString).lastPathComponent), #line, #function, redPacket.status.rawValue)
                            return
                        }
                        
                        let rollbackStatus: RedPacketStatus = redPacket.create_nonce.value != nil ? .normal : .incoming
                        os_log("%{public}s[%{public}ld], %{public}s: rollback red packet status to %s", ((#file as NSString).lastPathComponent), #line, #function, rollbackStatus.rawValue)
                        try realm.write {
                            redPacket.claim_address = nil
                            redPacket.claim_transaction_hash = nil
                            redPacket.status = rollbackStatus
                        }
                    } catch {
                        os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    }
                    
                }, afterCompleted: {
                    os_log("%{public}s[%{public}ld], %{public}s: afterCompleted claimResult", ((#file as NSString).lastPathComponent), #line, #function)
                    self.updateClaimResultQueue[id] = nil
                })
                .subscribe()
                .disposed(by: disposeBag)
            
            updateClaimResultQueue[id] = shared
            return shared
        }
        
        os_log("%{public}s[%{public}ld], %{public}s: use updateClaimResult in queue", ((#file as NSString).lastPathComponent), #line, #function)
        return observable
    }
    
}

extension RedPacketService {
    
    struct ClaimSuccess {
        let id: String
        let claimer: String
        let claimed_value: BigUInt
    }
    
}
