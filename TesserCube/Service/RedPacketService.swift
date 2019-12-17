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
import BigInt
import Web3

final class RedPacketService {
    
    // per packet. 0.002025 ETH
    public static var redPacketMinAmount: Decimal {
        return Decimal(0.002025)
    }
    
    // per packet. 0.002025 ETH
    public static var redPacketMinAmountInWei: BigUInt {
        return 2025000.gwei
    }
    
    public static let redPacketContractABIData: Data = {
        let path = Bundle(for: WalletService.self).path(forResource: "redpacket", ofType: "json")
        return try! Data(contentsOf: URL(fileURLWithPath: path!))
    }()
    
    public static var redPacketContractByteCode: EthereumData = {
        let path = Bundle(for: WalletService.self).path(forResource: "redpacket", ofType: "bin")
        let bytesString = try! String(contentsOfFile: path!)
        return try! EthereumData(ethereumValue: bytesString.trimmingCharacters(in: .whitespacesAndNewlines))
    }()

    public static func redPacketContract(for address: EthereumAddress?, web3: Web3) throws -> DynamicContract {
        let contractABIData = redPacketContractABIData
        do {
            return try web3.eth.Contract(json: contractABIData, abiKey: nil, address: address)
        } catch {
            throw Error.internal
        }
    }
    
    static var realmConfiguration: Realm.Configuration {
        var config = Realm.Configuration()
        
        let realmName = "RedPacket_v2"
        config.fileURL = TCDBManager.dbDirectoryUrl.appendingPathComponent("\(realmName).realm")
        config.objectTypes = [RedPacket.self]
        
        // setup migration
        let schemeVersion: UInt64 = 4
        config.schemaVersion = schemeVersion
        config.migrationBlock = { migration, oldSchemeVersion in
            if oldSchemeVersion < 1 {
                // auto migrate
            }
        }
        
        return config
    }
    
    static func realm() throws -> Realm {
        let config = RedPacketService.realmConfiguration
    
        try? FileManager.default.createDirectory(at: config.fileURL!.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
        
        return try Realm(configuration: config)
    }
    
    // MARK: - Singleton
    public static let shared = RedPacketService()
    
    private init() {
        _ = try? RedPacketService.realm()
    }

}

extension RedPacketService {
    
    static func validate(message: Message) -> Bool {
        let rawMessage = message.rawMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        return rawMessage.hasPrefix("-----BEGIN RED PACKET-----") && rawMessage.hasSuffix("-----END RED PACKET-----")
    }
    
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
    
}

extension RedPacketService {
    
    func redPacket(from message: Message) -> RedPacket? {
        return nil
//        guard let contractAddress = RedPacketService.contractAddress(for: message) else {
//            return nil
//        }
//
//        let uuids = RedPacketService.uuids(for: message)
//
//        guard !uuids.isEmpty, let userID = RedPacketService.userID(for: message) else {
//            return nil
//        }
//
//        let results = realm?.objects(RedPacket.self).filter { $0.contractAddress == contractAddress }
//        guard let redPacket = results?.first else {
//            let redPacket = RedPacket()
//            redPacket.senderUserID = userID
//            redPacket.share = uuids.count
//            redPacket.status = .incoming
//            redPacket.contractAddress = contractAddress
//            redPacket.uuids.append(objectsIn: uuids)
//
//            try! realm?.write {
//                realm?.add(redPacket)
//            }
//
//            return redPacket
//        }
//
//        return redPacket
    }
    
}

extension RedPacketService {
    enum Error: Swift.Error {
        case `internal`
    }
}

extension RedPacketService.Error: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .internal:    return "Web3 Contract Internal Error"
        }
    }
}
