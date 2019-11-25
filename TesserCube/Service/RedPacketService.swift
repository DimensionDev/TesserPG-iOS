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
