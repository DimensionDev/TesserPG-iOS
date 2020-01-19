//
//  RedPacketService+Approve.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-13.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import os
import Foundation
import RxSwift
import RxCocoa
import Web3

extension RedPacketService {
    
    static func approve(for redPacket: RedPacket, use walletModel: WalletModel, on erc20Token: ERC20Token, nonce: EthereumQuantity) -> Single<TransactionHash> {
        // Only for contract v1
        assert(redPacket.contract_version == 1)
        
        // Only initial red packet can process `create` on the contract
        guard redPacket.status == .initial else {
            assertionFailure()
            return Single.error(Error.internal("cannot created red packet repeatedly"))
        }
        
        // Init wallet
        guard redPacket.sender_address == walletModel.address else {
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
        let network = redPacket.network
        let web3 = Web3Secret.web3(for: network)
        let chainID = Web3Secret.chainID(for: network)
        
        // Init erc20 contract
        guard let erc20ContractAddress = try? EthereumAddress(hex: erc20Token.address, eip55: false) else {
            return Single.error(Error.internal("cannot construct erc20 contract"))
        }
        let erc20Contract = GenericERC20Contract(address: erc20ContractAddress, eth: web3.eth)

        // Prepare parameters
        guard let spender = try? EthereumAddress(hex: redPacket.contract_address, eip55: false) else {
            return Single.error(Error.internal("cannot construct spender address"))
        }
        
        let gasLimit = EthereumQuantity(integerLiteral: 1000000)
        let gasPrice = EthereumQuantity(quantity: 10.gwei)

        let approveInvocation = erc20Contract.approve(spender: spender, value: redPacket.send_total)
        guard let approveTransaction = approveInvocation.createTransaction(nonce: nonce, from: walletAddress, value: 0, gas: gasLimit, gasPrice: gasPrice) else {
            return Single.error(Error.internal("cannot construct approve transaction"))
        }
        
        let signedApproveTransaction: EthereumSignedTransaction
        do {
            signedApproveTransaction = try approveTransaction.sign(with: walletPrivateKey, chainId: chainID)
        } catch {
            return Single.error(Error.internal("cannot sign approve transaction"))
        }
        
        return Single<TransactionHash>.create { single -> Disposable in
            web3.eth.sendRawTransaction(transaction: signedApproveTransaction) { response in
                switch response.status {
                case .success(let transactionHash):
                    single(.success(transactionHash))
                case .failure(let error):
                    single(.error(error))
                }
            }
            
            return Disposables.create { }
        }
    }
    
    private static func approveResult(for redPacket: RedPacket) -> Single<ApproveEvent> {
        // Only for contract v1
        assert(redPacket.contract_version == 1)
        
        guard let approveTransactionHashHex = redPacket.erc20_approve_transaction_hash else {
            return Single.error(Error.internal("cannot read create transaction hash"))
        }
        
        let approveTransactionHash: TransactionHash
        do {
            let ethernumValue = EthereumValue(stringLiteral: approveTransactionHashHex)
            approveTransactionHash = try EthereumData(ethereumValue: ethernumValue)
        } catch {
            return Single.error(Error.internal("cannot read approve transaction hash"))
        }
        
        // Init web3
        let network = redPacket.network
        let web3 = Web3Secret.web3(for: network)
        
        // Prepare decoder
        
        return Single<ApproveEvent>.create { single -> Disposable in
            web3.eth.getTransactionReceipt(transactionHash: approveTransactionHash) { response in
                switch response.status {
                case let .success(receipt):
                    // Receipt return status => success
                    // Should read CreationSuccess log otherwise throw creationFail error
                    guard let status = receipt?.status, status.quantity == 1 else {
                        single(.error(Error.approveFail))
                        return
                    }
                    
                    guard let logs = receipt?.logs else {
                        single(.error(Error.approveFail))
                        return
                    }
                    
                    var resultDict: [String: Any]?
                    for log in logs {
                        guard let result = try? ABI.decodeLog(event: GenericERC20Contract.Approval, from: log) else {
                            continue
                        }
                        
                        resultDict = result
                        break
                    }
                    
                    guard let dict = resultDict,
                    let owner = dict["_owner"] as? EthereumAddress,
                    let spender = dict["_spender"] as? EthereumAddress,
                    let value = dict["_value"] as? BigUInt else {
                        single(.error(Error.approveFail))
                        return
                    }
                    
                    let event = ApproveEvent(owner: owner, spender: spender, value: value)
                    single(.success(event))
                    
                case let .failure(error):
                    if let rpcError = error as? RPCResponse<EthereumTransactionReceiptObject?>.Error {
                        single(.error(Error.internal(rpcError.message)))
                    } else {
                        single(.error(error))
                    }
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
    
    // Shared Observable sequeue from Single<ApproveEvent>
    func approveResult(for redPacket: RedPacket) -> Observable<ApproveEvent> {
        let id = redPacket.id
        var queue = approveResultQueue
        
        guard let observable = queue[id] else {
            let single = RedPacketService.approveResult(for: redPacket)
            let shared = single.asObservable().share()
            queue[id] = shared
            
            // Subscribe in service to prevent task canceled
            shared
                .asSingle()
                .do(afterSuccess: { _ in
                    os_log("%{public}s[%{public}ld], %{public}s: afterSuccess approveEvent", ((#file as NSString).lastPathComponent), #line, #function)
                    queue[id] = nil
                }, afterError: { _ in
                    os_log("%{public}s[%{public}ld], %{public}s: afterError approveEvent", ((#file as NSString).lastPathComponent), #line, #function)
                    queue[id] = nil
                })
                .subscribe()
                .disposed(by: disposeBag)
            
            return shared
        }
        
        os_log("%{public}s[%{public}ld], %{public}s: use approveResult in queue", ((#file as NSString).lastPathComponent), #line, #function)
        return observable
    }
    
    func updateApproveResult(for redPacket: RedPacket) -> Observable<ApproveEvent> {
        let id = redPacket.id
        var queue = approveResultQueue
        
        guard let observable = approveResultQueue[id] else {
            let single = self.approveResult(for: redPacket)
            let shared = single.asObservable().share()
            queue[id] = shared
            
            // Subscribe in service to prevent task canceled
            shared
                .asSingle()
                .do(onSuccess: { approveEvent in
                    do {
                        let realm = try RedPacketService.realm()
                        guard let redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
                            return
                        }
                        
                        guard redPacket.status == .pending else {
                            os_log("%{public}s[%{public}ld], %{public}s: discard change due to red packet status already %s.", ((#file as NSString).lastPathComponent), #line, #function, redPacket.status.rawValue)
                            return
                        }
                        
                        os_log("%{public}s[%{public}ld], %{public}s: change red packet erc20_approve_value to %s", ((#file as NSString).lastPathComponent), #line, #function, String(approveEvent.value))
                        try realm.write {
                            redPacket.erc20_approve_value = approveEvent.value
                        }
                    } catch {
                        os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    }
                    
                }, afterSuccess: { _ in
                    os_log("%{public}s[%{public}ld], %{public}s: afterSuccess updateApproveResult", ((#file as NSString).lastPathComponent), #line, #function)
                    queue[id] = nil
                    
                }, onError: { error in
                    switch error {
                    case RedPacketService.Error.approveFail:
                        do {
                            let realm = try RedPacketService.realm()
                            guard let redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else { return }
                            
                            try realm.write {
                                redPacket.status = .fail
                            }
                        } catch {
                            os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        }
                    default:
                        break
                    }
                    
                }, afterError: { error in
                    os_log("%{public}s[%{public}ld], %{public}s: afterError updateCreateResult", ((#file as NSString).lastPathComponent), #line, #function)
                    queue[id] = nil
                })
                .subscribe()
                .disposed(by: disposeBag)
            
            return shared
        }
        
        os_log("%{public}s[%{public}ld], %{public}s: use updateCreateResult in queue", ((#file as NSString).lastPathComponent), #line, #function)
        return observable
    }
}

extension RedPacketService {
    
    struct ApproveEvent {
        let owner: EthereumAddress
        let spender: EthereumAddress
        let value: BigUInt
    }
    
}
