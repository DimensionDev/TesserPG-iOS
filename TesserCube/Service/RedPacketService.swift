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
    
    // Global observable queue:
    // Reuse sequence if shared observable object if already in queue
    // And also subscribe in service when observable created to prevent task canceled
    var approveResultQueue: [RedPacket.ID: Observable<ApproveEvent>] = [:] {
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
        
        DispatchQueue.global().async {
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
    }

}
