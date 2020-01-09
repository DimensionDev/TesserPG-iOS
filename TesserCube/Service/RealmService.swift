//
//  RealmService.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-9.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import os
import Foundation
import RealmSwift

private enum SchemaVersions: UInt64 {
    case version_1 = 1
    case version_2_rc1 = 4
    case version_2_rc2 = 5
    case version_2_rc3 = 8
    case version_2_rc4 = 9
    case version_2_rc5 = 10
    case version_2_rc6 = 11
    case version_2_rc7 = 12
    
    static let currentVersion: SchemaVersions = .version_2_rc7
}

final class RealmService {

    // MARK: - Singleton
    public static let shared = RealmService()
    
    private init() {
        
    }

}

extension RealmService {
    
    static var realmConfiguration: Realm.Configuration {
        var config = Realm.Configuration()
        
        let realmName = "RedPacket_v2"
        config.fileURL = TCDBManager.dbDirectoryUrl.appendingPathComponent("\(realmName).realm")
        config.objectTypes = [RedPacket.self, ERC20Token.self, WalletObject.self, WalletToken.self]
        
        // setup migration
        let schemeVersion: UInt64 = SchemaVersions.currentVersion.rawValue
        config.schemaVersion = schemeVersion
        config.migrationBlock = { migration, oldSchemeVersion in
            if oldSchemeVersion < SchemaVersions.version_2_rc1.rawValue {
                // auto migrate
            }
            if oldSchemeVersion < SchemaVersions.version_2_rc2.rawValue {
                // auto migrate
            }
            if oldSchemeVersion < SchemaVersions.version_2_rc3.rawValue {
                // add network property
                migration.enumerateObjects(ofType: RedPacket.className()) { old, new in
                    new?["_network"] = EthereumNetwork.rinkeby.rawValue
                }
            }
            if oldSchemeVersion < SchemaVersions.version_2_rc4.rawValue {
                // auto migrate
            }
            if oldSchemeVersion < SchemaVersions.version_2_rc5.rawValue {
                // auto migrate
            }
            if oldSchemeVersion < SchemaVersions.version_2_rc6.rawValue {
                migration.renameProperty(onType: WalletObject.className(), from: "_balance", to: "_eth_balance") // Renaming
            }
            if oldSchemeVersion < SchemaVersions.version_2_rc7.rawValue {
                // auto migrate
            }
        }
        
        return config
    }
    
    static func realm() throws -> Realm {
        let config = RealmService.realmConfiguration
        
        try? FileManager.default.createDirectory(at: config.fileURL!.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
        
        do {
            return try Realm(configuration: config)
        } catch {
            os_log("%{public}s[%{public}ld], %{public}s: realm create fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            throw error
        }
    }
    
}
