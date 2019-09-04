//
//  ContactDBAction.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/27.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import DMSOpenPGP
import GRDB
import ConsolePrint

extension Contact {
    
    static func loadContact(id: Int64) -> Contact? {
        do {
            return try TCDBManager.default.dbQueue.read { db in
                try Contact.fetchOne(db, key: id)
            }
        } catch let error {
            consolePrint(error.localizedDescription)
            return nil
        }
    }

    func getKeyRecords() -> [KeyRecord] {
        do {
            return try TCDBManager.default.dbQueue.read({ db in
                return try self.keys.fetchAll(db)
            })
        } catch {
            consolePrint(error.localizedDescription)
            return []
        }
    }

    func getKeys() -> [TCKey] {
        do {
            let keyRecords = try TCDBManager.default.dbQueue.read({ db in
                return try self.keys.fetchAll(db)
            })

            return keyRecords.compactMap { keyRecord in
                guard let armored = keyRecord.armored,
                let keyRing = try? DMSPGPKeyRing(armoredKey: armored) else {
                    // assertionFailure("KeyRecord should not empty except first time process database migrate")
                    return nil
                }
                return TCKey(keyRing: keyRing, from: keyRecord)
            }
        } catch {
            consolePrint(error.localizedDescription)
            return []
        }
    }

    func getEmails() -> [Email] {
        let emails = try? TCDBManager.default.dbQueue.read({ db in
            try self.emails.fetchAll(db)
        })
        return emails ?? []
    }
    
    static func getOwnerContacts(longIdentifier: String) -> [Contact] {
        let contacts = try? TCDBManager.default.dbQueue.read({ db -> [Contact] in
            let keyRecords = try KeyRecord.filter(Column("longIdentifier") == longIdentifier).fetchAll(db)
            return try Contact.fetchAll(db, keys: keyRecords.map { $0.contactId })
        })
        return contacts ?? []
    }

}

extension Contact {
    
    mutating func update(name: String, email: Email?) throws {
        do {
            try TCDBManager.default.dbQueue.write({ db in
                self.name = name
                try update(db)
                if let updatedEmail = email {
                    if updatedEmail.address.isEmpty {
                        try updatedEmail.delete(db)
                    } else {
                        try updatedEmail.update(db)
                    }
                }
            })
            if let contactId = id {
                ProfileService.default.contactChanged.accept([contactId])
            }
        } catch let error {
            throw error
        }
    }

}

extension Contact {

    func removeKey(_ key: TCKey) throws {
        do {
            let keyRecords = try TCDBManager.default.dbQueue.read({ db in
                return try self.keys.fetchAll(db)
            })

            guard let keyRecordNeedsRemove = keyRecords.first(where: { $0.longIdentifier == key.longIdentifier }) else {
                // nothing needs write
                return
            }

            let shouldRemoveContact = keyRecords.count == 1
            try TCDBManager.default.dbQueue.write { db in
                if shouldRemoveContact {
                    try self.delete(db)
                    // cascade delete key record
                } else {
                    try keyRecordNeedsRemove.delete(db)
                }
            }

        } catch {
            consolePrint(error.localizedDescription)
            throw error
        }
    }

}
