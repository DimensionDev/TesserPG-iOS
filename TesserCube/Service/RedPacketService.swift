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
    var createResultQueue: [RedPacket.ID: Observable<CreationSuccess>] = [:]
    var updateCreateResultQueue: [RedPacket.ID: Observable<CreationSuccess>] = [:]
    var checkAvailabilityQueue: [RedPacket.ID: Observable<RedPacketAvailability>] = [:]
    var claimQueue: [RedPacket.ID: Observable<TransactionHash>] = [:]
    var claimResultQueue: [RedPacket.ID: Observable<ClaimSuccess>] = [:]
    var updateClaimResultQueue: [RedPacket.ID: Observable<ClaimSuccess>] = [:]
    var refundQueue: [RedPacket.ID: Observable<TransactionHash>] = [:]
    var refundResultQueue: [RedPacket.ID: Observable<RefundSuccess>] = [:]
    var updateRefundResultQueue: [RedPacket.ID: Observable<RefundSuccess>] = [:]
    
    // per packet. 0.002025 ETH
    public static var redPacketMinAmount: Decimal {
        return Decimal(0.002025)
    }
    
    // per packet. 0.002025 ETH
    public static var redPacketMinAmountInWei: BigUInt {
        return 2025000.gwei
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
        guard let realm = try? RedPacketService.realm() else {

            assertionFailure()
            return
        }
        
        let tokens = realm.objects(ERC20Token.self)
        guard tokens.isEmpty else {
            return
        }
        
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
            return preloadMainnetTokens.contains(where: { $0.address != token.address })
        }
        
        try? realm.write {
            realm.add(preloadMainnetTokens)
            realm.add(preloadRinkebyTokens)
        }
    }

}

extension RedPacketService {
    
    /*
    static func validate(message: Message) -> Bool {
        let rawMessage = message.rawMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        return rawMessage.hasPrefix("-----BEGIN RED PACKET-----") && rawMessage.hasSuffix("-----END RED PACKET-----")
    }
     */
    
    /*
    static func contractAddress(for message: Message) -> String? {
        guard validate(message: message) else {
            return nil
        }
        
        let scanner = Scanner(string: message.rawMessage.trimmingCharacters(in: .whitespacesAndNewlines))
        scanner.charactersToBeSkipped = nil
        // Jump to begin
        scanner.scanUpTo("-----BEGIN RED PACKET-----", into: nil)
        // Read -----BEGIN RED PACKET-----\r\n
        scanner.scanUpToCharacters(from: .newlines, into: nil)
        scanner.scanCharacters(from: .newlines, into: nil)
        // Read [fingerprint]:[userID]
        scanner.scanUpToCharacters(from: .newlines, into: nil)
        scanner.scanCharacters(from: .newlines, into: nil)
        
        var contractAddress: NSString?
        scanner.scanUpToCharacters(from: .newlines, into: &contractAddress)
        
        return contractAddress as String?
    }
     */
    
    /*
    static func userID(for message: Message) -> String? {
        guard validate(message: message) else {
            return nil
        }
        
        let scanner = Scanner(string: message.rawMessage.trimmingCharacters(in: .whitespacesAndNewlines))
        scanner.charactersToBeSkipped = nil
        scanner.scanUpTo(":", into: nil)
        // Read user id
        var userID: NSString?
        scanner.scanUpToCharacters(from: .newlines, into: &userID)
        
        return userID as String?
    }
     */
    
    /*
    static func uuids(for message: Message) -> [String] {
        guard validate(message: message) else {
            return []
        }
        
        let scanner = Scanner(string: message.rawMessage.trimmingCharacters(in: .whitespacesAndNewlines))
        scanner.charactersToBeSkipped = nil
        // Jump to begin
        scanner.scanUpTo("-----BEGIN RED PACKET-----", into: nil)
        // Read -----BEGIN RED PACKET-----\r\n
        scanner.scanUpToCharacters(from: .newlines, into: nil)
        scanner.scanCharacters(from: .newlines, into: nil)
        // Read [fingerprint]:[userID]
        scanner.scanUpToCharacters(from: .newlines, into: nil)
        scanner.scanCharacters(from: .newlines, into: nil)
        // Read contract address
        scanner.scanUpToCharacters(from: .newlines, into: nil)
        scanner.scanCharacters(from: .newlines, into: nil)
        
        var uuids: NSString?
        scanner.scanUpTo("-----END RED PACKET-----", into: &uuids)
        
        guard let uuidsString = uuids?.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n") else {
            return []
        }
        
        return uuidsString as [String]
    }
     */
    
}

extension RedPacketService {
    
}
