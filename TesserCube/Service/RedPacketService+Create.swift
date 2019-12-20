//
//  RedPacketService+Create.swift
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
    
    static func createResult(for redPacket: RedPacket) -> Single<CreationSuccess> {
        // Only for contract v1
        assert(redPacket.contract_version == 1)
        
        guard let createTransactionHashHex = redPacket.create_transaction_hash else {
            return Single.error(Error.internal("cannot read create transaction hash"))
        }
        
        let createTransactionHash: TransactionHash
        do {
            let ethernumValue = EthereumValue(stringLiteral: createTransactionHashHex)
            createTransactionHash = try EthereumData(ethereumValue: ethernumValue)
            
        } catch {
            return Single.error(Error.internal("cannot read create transaction hash"))
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
        guard let creationSuccessEvent = (contract.events.filter { $0.name == "CreationSuccess" }.first) else {
            return Single.error(Error.internal("cannot read creation event from contract"))
        }
        
        return Single<CreationSuccess>.create { single -> Disposable in
            web3.eth.getTransactionReceipt(transactionHash: createTransactionHash) { response in
                switch response.status {
                case let .success(receipt):
                    // Receipt return status => success
                    // Should read CreationSuccess log otherwise throw creationFail error
                    guard let status = receipt?.status, status.quantity == 1 else {
                        single(.error(Error.creationFail))
                        return
                    }
                    
                    guard let logs = receipt?.logs else {
                        single(.error(Error.creationFail))
                        return
                    }
                    
                    var resultDict: [String: Any]?
                    for log in logs {
                        guard let result = try? ABI.decodeLog(event: creationSuccessEvent, from: log) else {
                            continue
                        }
                        
                        resultDict = result
                        break
                    }

                    guard let dict = resultDict,
                    let total = dict["total"] as? BigUInt,
                    let idBytes = dict["id"] as? Data,
                    let creator = dict["creator"] as? EthereumAddress,
                    let creation_time = dict["creation_time"] as? BigUInt else {
                        single(.error(Error.creationFail))
                        return
                    }
                    
                    let event = CreationSuccess(total: total,
                                                id: idBytes.toHexString(),
                                                creator: creator.hex(eip55: true),
                                                creation_time: Int(creation_time))
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
                
                os_log("%{public}s[%{public}ld], %{public}s: fetch create result fail. Retry %s times", ((#file as NSString).lastPathComponent), #line, #function, String(index + 1))
                
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
    
    func updateCreateResult(for redPacket: RedPacket) -> Observable<CreationSuccess> {
        // should call on main thread to make sure realm operation in subscribe is thread safe
        assert(Thread.isMainThread)
        let id = redPacket.id
        
        let observable = Observable.just(id)
            .flatMap { id -> Observable<RedPacketService.CreationSuccess> in
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
                
                return RedPacketService.createResult(for: redPacket).asObservable()
                    .retry(3)   // network retry
        }
        .observeOn(MainScheduler.instance)
        .share()
        
        observable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { creationSuccess in
                do {
                    let realm = try RedPacketService.realm()
                    guard let redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
                        return
                    }
                    
                    guard redPacket.status == .pending else {
                        os_log("%{public}s[%{public}ld], %{public}s: discard change due to red packet status already %s.", ((#file as NSString).lastPathComponent), #line, #function, redPacket.status.rawValue)
                        return
                    }
                    
                    try realm.write {
                        redPacket.red_packet_id = creationSuccess.id
                        redPacket.block_creation_time.value = creationSuccess.creation_time
                        redPacket.status = .normal
                    }
                } catch {
                    os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                }
            }, onError: { error in
                switch error {
                case RedPacketService.Error.creationFail:
                    do {
                        let realm = try RedPacketService.realm()
                        guard let redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
                            return
                        }
                        
                        try realm.write {
                            redPacket.status = .fail
                        }
                    } catch {
                        os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    }
                default:
                    break
                }
                
            })
            .disposed(by: disposeBag)
        
        return observable
    }
    
}

extension RedPacketService {
    
    struct CreationSuccess {
        let total: BigUInt
        let id: String
        let creator: String
        let creation_time: Int
    }
    
}

