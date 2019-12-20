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
    
    static func claimResult(for redPacket: RedPacket) -> Single<ClaimSuccess> {
        // Only for contract v1
        assert(redPacket.contract_version == 1)
        
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
        guard let contractAddressString = redPacket.contract_address else {
            return Single.error(Error.internal("cannot get red packet contract address"))
        }
        
        let contract: DynamicContract
        do {
            contract = try RedPacketService.prepareContract(for: contractAddressString, in: web3)
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
    
    func updateClaimResult(for redPacket: RedPacket) -> Observable<ClaimSuccess> {
        os_log("%{public}s[%{public}ld], %{public}s: update claim result for red packet - %s", ((#file as NSString).lastPathComponent), #line, #function, redPacket.red_packet_id ?? "nil")

        let id = redPacket.id
        
        let observable = Observable.just(id)
            .flatMap { id -> Observable<RedPacketService.ClaimSuccess> in
                let redPacket: RedPacket
                do {
                    let realm = try RedPacketService.realm()
                    guard let _redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
                        return Observable.error(RedPacketService.Error.internal("cannot resolve red packet"))
                    }
                    redPacket = _redPacket
                } catch {
                    return Observable.error(error)
                }
                
                return RedPacketService.claimResult(for: redPacket).asObservable()
                    .retry(3)   // network retry
        }
        .observeOn(MainScheduler.instance)
        .share()
        
        observable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { claimSuccess in
                do {
                    let realm = try RedPacketService.realm()
                    guard let redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
                        return
                    }
                    
                    guard redPacket.status == .claim_pending else {
                        os_log("%{public}s[%{public}ld], %{public}s: discard change due to red packet status already %s.", ((#file as NSString).lastPathComponent), #line, #function, redPacket.status.rawValue)
                        return
                    }
                    
                    try realm.write {
                        redPacket.claim_amount = claimSuccess.claimed_value
                        redPacket.status = .claimed
                    }
                } catch {
                    os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                }
            }, onError: { error in
                switch error {
                case RedPacketService.Error.claimFail:
                    do {
                        let realm = try RedPacketService.realm()
                        guard let redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
                            return
                        }
                        
                        guard redPacket.status == .claim_pending else {
                            os_log("%{public}s[%{public}ld], %{public}s: discard change due to red packet status already %s. not .claim_pending", ((#file as NSString).lastPathComponent), #line, #function, redPacket.status.rawValue)
                            return
                        }
                        
                        try realm.write {
                            let rollbackStatus: RedPacketStatus = redPacket.create_nonce.value != nil ? .normal : .incoming
                            redPacket.claim_address = nil
                            redPacket.claim_transaction_hash = nil
                            redPacket.status = rollbackStatus
                        }
                    } catch {
                        os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    }
                default:
                    // not chain error
                    break
                }
                
            })
            .disposed(by: disposeBag)
        
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
