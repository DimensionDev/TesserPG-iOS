//
//  TCDBManager.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/26.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import GRDB

class TCDBManager {
    
    static let `default` = TCDBManager()
    
    private static let dbDirectoryName = "db"
    private static let dbFileName = "tc.sqlite"
    
    private static let dbVersion = "2019090201"
    
    let dbQueue: DatabaseQueue
    
    init() {
        do {
            dbQueue = try DatabaseQueue(path: TCDBManager.dbFilePath)
            try registerMigration()
        } catch let error {
            fatalError("db creation error: \(error.localizedDescription)")
        }
    }
    
    func test() {
        do {
            try dbQueue.write { db in
                var contact = Contact(id: nil, name: "Brad Gao")
                try contact.insert(db)
                var email = Email(id: nil, address: "bradgao@email.com", contactId: contact.id!)
                try email.insert(db)
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }
        
    }
    
    private func registerMigration() throws {
        do {
            var migrator = DatabaseMigrator()
            migrator.registerMigration("2019032601") { db in
                try db.create(table: "contact", body: { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("name", .text).notNull().indexed()
                })
                try db.create(table: "email", body: { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("address", .text).notNull()
                    t.column("contactId", .integer).notNull().indexed().references("contact", onDelete: .cascade)
                })
                try db.create(table: "keyRecord", body: { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("longIdentifier", .text).notNull()
                    t.column("hasSecretKey", .boolean).notNull()
                    t.column("hasPublicKey", .boolean).notNull()
                    t.column("contactId", .integer).notNull().indexed().references("contact", onDelete: .cascade)
                })
                
                try db.create(table: "message", body: { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("senderKeyId", .text).notNull()
                    t.column("senderKeyUserId", .text).notNull()
                    t.column("composedAt", .datetime)
                    t.column("interpretedAt", .datetime)
                    t.column("isDraft", .boolean).notNull().defaults(to: false)
                    t.column("rawMessage", .text)
                    t.column("encryptedMessage", .text)
                })
                
                try db.create(table: "messageRecipient", body: { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("messageId", .integer).notNull().references("message", onDelete: .cascade)
                    t.column("keyId", .text).notNull()
                    t.column("keyUserId", .text).notNull()
                })
            }
            migrator.registerMigration("StoreKeyInDB") { db in
                try db.alter(table: "keyRecord", body: { t in
                    t.add(column: "armored", .text)
                })
                let allKeys = KeyFactory.legacyLoadKeys()

                let allKeyRecords = try KeyRecord.fetchAll(db)
                for var perKeyRecord in allKeyRecords {
                    for legacyKey in allKeys {
                        if let tcKey = TCKey(armored: legacyKey), tcKey.longIdentifier == perKeyRecord.longIdentifier {
                            perKeyRecord.armored = legacyKey
                            try perKeyRecord.update(db)
                        }
                    }
                }
            }
            try migrator.migrate(dbQueue)
        } catch let error {
            print("migration fails")
            throw error
        }
    }
}

extension TCDBManager {
    static var dbDirectoryUrl: URL = {
        let directoryUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.sujitech.tessercube")!
        let keysDirectoryUrl = directoryUrl.appendingPathComponent(TCDBManager.dbDirectoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: keysDirectoryUrl.absoluteString) {
            try? FileManager.default.createDirectory(at: keysDirectoryUrl, withIntermediateDirectories: true, attributes: nil)
        }
        return keysDirectoryUrl
    }()
    
    static var dbFilePath: String = {
        return dbDirectoryUrl.appendingPathComponent(dbFileName).path
    }()
}
