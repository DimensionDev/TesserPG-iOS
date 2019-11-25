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

final class RedPacketService {
    
    let realm: Realm? = {
        var config = Realm.Configuration()
        let realmName = "RedPacket"
        config.fileURL = TCDBManager.dbDirectoryUrl.appendingPathComponent("\(realmName).realm")
        config.objectTypes = [RedPacket.self]
        
        try? FileManager.default.createDirectory(at: config.fileURL!.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        
        // setup migration
        let schemeVersion: UInt64 = 1
        config.schemaVersion = schemeVersion
        config.migrationBlock = { migration, oldSchemeVersion in
            if oldSchemeVersion < 1 {
                // auto migrate
            }
        }
        
        do {
            return try Realm(configuration: config)
        } catch {
            os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)

            return nil
        }
    }()
    
    // MARK: - Singleton
    public static let shared = RedPacketService()
    
    private init() { }

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
    
}


extension RedPacketService {
    
    func redPacket(from message: Message) -> RedPacket? {
        guard let contractAddress = RedPacketService.contractAddress(for: message) else {
            return nil
        }
        
        let results = realm?.objects(RedPacket.self).filter { $0.contractAddress == contractAddress }
        guard let redPacket = results?.first else {
            return nil
        }
        
        return redPacket
    }
    
}
