//
//  RedPacketService.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-25.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import Foundation
import RealmSwift
import RxSwift
import RxRealm
import BigInt
import Web3

public struct PreloadERC20Token: Codable {
    let address: String
    let name: String
    let symbol: String
    let decimals: Int
}

final class RedPacketService {
    
    let disposeBag = DisposeBag()
    
    let threadSafeQueue = DispatchQueue(label: "TreadSafeQueue", attributes: .concurrent)

    // Global observable queue:
    // Reuse sequence if shared observable object if already in queue
    // And also subscribe in service when observable created to prevent task canceled
    var approveResultQueue: [RedPacket.ID: Observable<ApproveEvent>] = [:] {
        didSet { isQueueChanged.onNext(()) }
    }
    var createAfterApproveQueue: [RedPacket.ID: Observable<TransactionHash>] = [:] {
        didSet { isQueueChanged.onNext(()) }
    }
    var createQueue: [RedPacket.ID: Observable<TransactionHash>] = [:] {
        didSet { isQueueChanged.onNext(()) }
    }
    var createResultQueue: [RedPacket.ID: Observable<CreationSuccess>] = [:] {
        didSet { isQueueChanged.onNext(()) }
    }
    var updateCreateResultQueue: [RedPacket.ID: Observable<CreationSuccess>] = [:] {
        didSet { isQueueChanged.onNext(()) }
    }
    var checkAvailabilityQueue: [RedPacket.ID: Observable<RedPacketAvailability>] = [:] {
        didSet { isQueueChanged.onNext(()) }
    }
    var claimQueue: [RedPacket.ID: Observable<TransactionHash>] = [:] {
        didSet { isQueueChanged.onNext(()) }
    }
    var claimResultQueue: [RedPacket.ID: Observable<ClaimSuccess>] = [:] {
        didSet { isQueueChanged.onNext(()) }
    }
    var updateClaimResultQueue: [RedPacket.ID: Observable<ClaimSuccess>] = [:] {
        didSet { isQueueChanged.onNext(()) }
    }
    var refundQueue: [RedPacket.ID: Observable<TransactionHash>] = [:] {
        didSet { isQueueChanged.onNext(()) }
    }
    var refundResultQueue: [RedPacket.ID: Observable<RefundSuccess>] = [:] {
        didSet { isQueueChanged.onNext(()) }
    }
    var updateRefundResultQueue: [RedPacket.ID: Observable<RefundSuccess>] = [:] {
        didSet { isQueueChanged.onNext(()) }
    }
    
    // Output
    let isQueueChanged = PublishSubject<Void>()
    
    // per packet. 0.001 ETH
    public static var redPacketMinAmount: Decimal {
        return Decimal(0.001)
    }
    
    // per packet. 0.001 ETH
    public static var redPacketMinAmountInWei: BigUInt {
        return 1000000.gwei
    }
    
    public static let redPacketContractABIData: Data = {
        let path = Bundle(for: RedPacketService.self).path(forResource: "redpacket", ofType: "json")
        return try! Data(contentsOf: URL(fileURLWithPath: path!))
    }()
    
    public static var redPacketContractByteCode: EthereumData = {
        let path = Bundle(for: RedPacketService.self).path(forResource: "redpacket", ofType: "bin")
        let bytesString = try! String(contentsOfFile: path!)
        return try! EthereumData(ethereumValue: bytesString.trimmingCharacters(in: .whitespacesAndNewlines))
    }()
    
    public static var preloadMainnetERC20Token: [PreloadERC20Token] = {
        let path = Bundle(for: RedPacketService.self).path(forResource: "mainnet-erc20", ofType: "json")
        let jsonData = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let decoder = JSONDecoder()
        let tokens = try? decoder.decode([PreloadERC20Token].self, from: jsonData)
        return tokens ?? []
    }()
    
    public static var preloadRopstenERC20Token: [PreloadERC20Token] = {
        let path = Bundle(for: RedPacketService.self).path(forResource: "ropsten-erc20", ofType: "json")
        let jsonData = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let decoder = JSONDecoder()
        let tokens = try? decoder.decode([PreloadERC20Token].self, from: jsonData)
        return tokens ?? []
    }()
    
    public static var preloadRinkebyERC20Token: [PreloadERC20Token] = {
        let path = Bundle(for: RedPacketService.self).path(forResource: "rinkeby-erc20", ofType: "json")
        let jsonData = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let decoder = JSONDecoder()
        let tokens = try? decoder.decode([PreloadERC20Token].self, from: jsonData)
        return tokens ?? []
    }()
    

    public static func redPacketContract(for address: EthereumAddress?, web3: Web3) throws -> DynamicContract {
        let contractABIData = redPacketContractABIData
        do {
            return try web3.eth.Contract(json: contractABIData, abiKey: nil, address: address)
        } catch {
            throw Error.internal("cannot initialize contract")
        }
    }
    
    static func realm() throws -> Realm {
        return try RealmService.realm()
    }
    
    // MARK: - Singleton
    public static let shared = RedPacketService()
    
    private init() {
        guard let _ = try? RedPacketService.realm() else {
            assertionFailure()
            return
        }
        
        // Fufill database
        DispatchQueue.global().async {
            self.populatePreloadData()
        }
        
        // Setup listener for RedPacket
        // And do not set listener in keyboard
        #if !TARGET_IS_KEYBOARD
        setupRedPacketTrigger()
        #endif
    }
    
    private func populatePreloadData() {
        guard let realm = try? RedPacketService.realm() else {
            return
        }
        
        let tokens = realm.objects(ERC20Token.self)
        guard tokens.isEmpty else {
            return
        }
        
        var preloadTokens: [ERC20Token] = []
        let preloadMainnetTokens: [ERC20Token] = RedPacketService.preloadMainnetERC20Token.map { preloadToken in
            let token = ERC20Token()
            token.id = preloadToken.address
            token.address = preloadToken.address
            token.name = preloadToken.name
            token.symbol = preloadToken.symbol
            token.decimals = preloadToken.decimals
            token.network = .mainnet
            token.is_user_defind = false
            return token
        }
        preloadTokens.append(contentsOf: preloadMainnetTokens)
        
        let preloadRopstenTokens: [ERC20Token] = RedPacketService.preloadRopstenERC20Token.map { preloadToken in
            let token = ERC20Token()
            token.id = preloadToken.address
            token.address = preloadToken.address
            token.name = preloadToken.name
            token.symbol = preloadToken.symbol
            token.decimals = preloadToken.decimals
            token.network = .ropsten
            token.is_user_defind = false
            return token
        }.filter { token in
            return preloadTokens.contains(where: { $0.address != token.address })
        }
        preloadTokens.append(contentsOf: preloadRopstenTokens)
        
        let preloadRinkebyTokens: [ERC20Token] = RedPacketService.preloadRinkebyERC20Token.map { preloadToken in
            let token = ERC20Token()
            token.id = preloadToken.address
            token.address = preloadToken.address
            token.name = preloadToken.name
            token.symbol = preloadToken.symbol
            token.decimals = preloadToken.decimals
            token.network = .rinkeby
            token.is_user_defind = false
            return token
        }.filter { token in
            return preloadTokens.contains(where: { $0.address != token.address })
        }
        preloadTokens.append(contentsOf: preloadRinkebyTokens)
        
        try? realm.write {
            realm.add(preloadTokens)
        }
    }
    
    private func setupRedPacketTrigger() {
        do {
            let realm = try RedPacketService.realm()
            let redPacketResults = realm.objects(RedPacket.self)
            Observable.array(from: redPacketResults, synchronousStart: false)
                .debounce(.milliseconds(300), scheduler: MainScheduler.instance)        // prevent task queue race issue
                .subscribe(onNext: { [weak self] redPackets in
                    guard let `self` = self else { return }
                    
                    // 1. fetch ERC20 approve result for pending red packet
                    //      RedPacket status is pending
                    //      RedPacket erc20_approve_transaction_hash not empty
                    //      RedPacket erc20_approve_value is empty
                    //      WalletModel at sender_address is avaliable
                    let pendingApproveResultRedPackets = redPackets.filter { redPacket in
                        guard redPacket.status == .pending, redPacket.erc20_approve_value == nil else { return false }
                        return true
                    }
                    for redPacket in pendingApproveResultRedPackets {
                        guard let _ = WalletService.default.walletModels.value.first(where: { $0.address == redPacket.sender_address }) else {
                            continue
                        }

                        let id = redPacket.id
                        os_log("%{public}s[%{public}ld], %{public}s: BG#1 - fetch updateApproveResult for RP - %s", ((#file as NSString).lastPathComponent), #line, #function, id)
                        return RedPacketService.shared.updateApproveResult(for: redPacket)
                            .retry(3)
                            .observeOn(MainScheduler.instance)
                            .subscribe(onNext: { approveEvent in
                                // do nothing.
                                // all dabase update operation trigger in the service
                                os_log("%{public}s[%{public}ld], %{public}s: BG#1 - updateApproveResult success for RP - %s", ((#file as NSString).lastPathComponent), #line, #function, id)
                            }, onError: { error in
                                os_log("%{public}s[%{public}ld], %{public}s: BG#1 - updateApproveResult failure for RP - %s. Reason: %s", ((#file as NSString).lastPathComponent), #line, #function, id, error.localizedDescription)
                            })
                            .disposed(by: self.disposeBag)
                        
                    }
                    
                    // 2. send create transaction if red packet ERC20 approve result is fetched
                    //      RedPacket status is pending
                    //      RedPacket create_transaction_hash is empty
                    //      RedPacket erc20_approve_value not empty
                    let pendingCreateAfterApproveRedPackets = redPackets.filter { redPacket in
                        guard redPacket.status == .pending, redPacket.erc20_approve_value != nil, redPacket.create_transaction_hash == nil else {
                            return false
                        }
                        
                        return true
                    }
                    for redPacket in pendingCreateAfterApproveRedPackets {
                        guard let walletModel = WalletService.default.walletModels.value.first(where: { $0.address == redPacket.sender_address }) else {
                            continue
                        }
                        
                        // Init web3
                        let network = redPacket.network
                        let web3 = Web3Secret.web3(for: network)
                        
                        let id = redPacket.id
                        os_log("%{public}s[%{public}ld], %{public}s: BG#2 - send createAfterApprove for RP - %s", ((#file as NSString).lastPathComponent), #line, #function, id)
                        let walletValue = WalletValue(from: walletModel)
                        let walletAddress: EthereumAddress
                        do {
                            walletAddress = try EthereumAddress(hex: walletValue.address, eip55: false)
                        } catch {
                            assertionFailure()
                            continue
                        }
                        WalletService.getTransactionCount(address: walletAddress, web3: web3)
                            .asObservable()
                            .subscribeOn(ConcurrentDispatchQueueScheduler.init(qos: .userInitiated))
                            .retry(3)
                            .observeOn(MainScheduler.instance)
                            .flatMap { nonce -> Observable<TransactionHash> in
                                os_log("%{public}s[%{public}ld], %{public}s: BG#2 - send createAfterApprove for RP - %s with nonce: %d", ((#file as NSString).lastPathComponent), #line, #function, id, Int(nonce.quantity))
                                return RedPacketService.shared.createAfterApprove(for: redPacket, use: walletValue, nonce: nonce)
                            }
                            .subscribe(onNext: { transactionHash in
                                os_log("%{public}s[%{public}ld], %{public}s: BG#2 - createAfterApprove success for RP - %s ", ((#file as NSString).lastPathComponent), #line, #function, id)
                            }, onError: { error in
                                os_log("%{public}s[%{public}ld], %{public}s: BG#2 - createAfterApprove failure for RP - %s. Reason: %s", ((#file as NSString).lastPathComponent), #line, #function, id, error.localizedDescription)
                            })
                            .disposed(by: self.disposeBag)
                    }
                    
                    // 3. fetch create transaction result
                    //      RedPacket status is pending
                    //      RedPacket create_transaction not empty
                    let pendingRedPackets = redPackets.filter { $0.status == .pending }
                    for redPacket in pendingRedPackets where redPacket.create_transaction_hash != nil {
                        let id = redPacket.id
                        os_log("%{public}s[%{public}ld], %{public}s: BG#3 - fetch updateCreateResult for RP - %s", ((#file as NSString).lastPathComponent), #line, #function, id)
                        RedPacketService.shared.updateCreateResult(for: redPacket)
                            .subscribe(onNext: { creationSuccess in
                                os_log("%{public}s[%{public}ld], %{public}s: BG#3 - updateCreateResult success for RP - %s", ((#file as NSString).lastPathComponent), #line, #function, id)
                            }, onError: { error in
                                os_log("%{public}s[%{public}ld], %{public}s: BG#3 - updateCreateResult failure for RP - %s. Reason %s ", ((#file as NSString).lastPathComponent), #line, #function, id, error.localizedDescription)
                            })
                            .disposed(by: self.disposeBag)
                    }
                    
                    // 4. fetch claim result
                    //      RedPacket status is claim_pending
                    let claimPendingRedPackets = redPackets.filter { $0.status == .claim_pending }
                    for redPacket in claimPendingRedPackets {
                        let id = redPacket.id
                        os_log("%{public}s[%{public}ld], %{public}s: BG#4 - updateClaimResult for RP - %s", ((#file as NSString).lastPathComponent), #line, #function, id)
                        RedPacketService.shared.updateClaimResult(for: redPacket)
                            .subscribe(onNext: { claimSuccess in
                                os_log("%{public}s[%{public}ld], %{public}s: BG#4 - updateClaimResult success for RP - %s", ((#file as NSString).lastPathComponent), #line, #function, id)
                            }, onError: { error in
                                os_log("%{public}s[%{public}ld], %{public}s: BG#4 - updateClaimResult failure for RP - %s. Reason %s", ((#file as NSString).lastPathComponent), #line, #function, id, error.localizedDescription)
                            })
                            .disposed(by: self.disposeBag)
                    }
                    
                    // 5. fetch refund result
                    //      RedPacket status is refund_pending
                    let refundPendingRedPackets = redPackets.filter { $0.status == .refund_pending }
                    for redPacket in refundPendingRedPackets {
                        let id = redPacket.id
                        os_log("%{public}s[%{public}ld], %{public}s: BG#5 - updateRefundResult for RP: %s", ((#file as NSString).lastPathComponent), #line, #function, id)
                        RedPacketService.shared.updateRefundResult(for: redPacket)
                            .subscribe(onNext: { refundSuccess in
                                os_log("%{public}s[%{public}ld], %{public}s: BG#5 - updateRefundResult success for RP - %s", ((#file as NSString).lastPathComponent), #line, #function, id)
                            }, onError: { error in
                                os_log("%{public}s[%{public}ld], %{public}s: BG#5 - updateRefundResult failure for RP - %s. Reason %s", ((#file as NSString).lastPathComponent), #line, #function, id, error.localizedDescription)
                            })
                            .disposed(by: self.disposeBag)
                    }
                    
                })
                .disposed(by: disposeBag)
            
        } catch {
            os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            assertionFailure()
        }
    }

}
