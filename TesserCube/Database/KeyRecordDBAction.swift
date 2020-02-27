//
//  KeyRecordDBAction.swift
//  TesserCube
//
//  Created by jk234ert on 2019/4/2.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import DMSGoPGP
import GRDB

extension KeyRecord {

    mutating func removeKeySecretPart() throws {
        guard let armored = armored else { return }
        guard let keyRing = try? CryptoGopenPGP().buildKeyRingArmored(armored) else {
            assertionFailure()
            return
        }
        
        let publicKeyArmored = keyRing.getArmoredPublicKey(nil)

        do {
            try TCDBManager.default.dbQueue.write { db in
                self.armored = publicKeyArmored
                self.hasSecretKey = false
                try update(db)
            }
        } catch {
            throw error
        }
    }
}

extension KeyRecord {

    // Remove keyRecord and owner contact side-effect
    static func remove(longIdentifier: [String]) throws {

        do {
            _ = try TCDBManager.default.dbQueue.write({ db in
                let keyRecords = try KeyRecord.filter(longIdentifier.contains(Column("longIdentifier"))).fetchAll(db)
                for keyRecord in keyRecords {
                    guard let contact = try? Contact.fetchOne(db, key: keyRecord.contactId) else {
                        assertionFailure("Key not belong to any contact")
                        try keyRecord.delete(db)
                        continue
                    }

                    let keysCount = try contact.keys.fetchCount(db)
                    let shouldRemoveContact = keysCount == 1

                    if shouldRemoveContact {
                        try contact.delete(db)
                        // cascade delete key record
                    } else {
                        try keyRecord.delete(db)
                    }

                }
            })
        } catch let error {
            throw error
        }
    }

}

extension KeyRecord {

    /// Delete key record from database
    /// And also remove contact if the owner contact.keys has no other key record
    @discardableResult
    func delete() -> Bool {
        do {
            return try TCDBManager.default.dbQueue.write { db -> Bool in
                guard let contact = try? Contact.fetchOne(db, key: contactId) else {
                    assertionFailure()      // key should belong to one contact
                    return try delete(db)
                }

                let keysCount = try contact.keys.fetchCount(db)
                let shouldRemoveContact = keysCount == 1

                if shouldRemoveContact {
                    return try contact.delete(db)
                    // cascade delete keyrecord
                } else {
                    return try delete(db)
                }
            }

        } catch {
            return false
        }
    }

}

extension KeyRecord {
    
    /// Update partial key
    /// - Parameters:
    ///   - tcKey: the secret key for update
    ///   - passphrase: passphrase for key
    mutating func updateKey(_ tcKey: TCKey, passphrase: String) throws {
        assert(tcKey.hasSecretKey)
        
        // 1. update keychain. Auth needs and should not in main thread
        assert(!Thread.isMainThread)
        let keychain = ProfileService.default.keyChain
        try keychain
            .authenticationPrompt("Authenticate to update your password")
            .set(passphrase, key: tcKey.longIdentifier)

        // 2. update keyRecord
        let privateArmored = try tcKey.getPrivateArmored(passprahse: passphrase)
        _ = try TCDBManager.default.dbQueue.write { db in
            self.hasSecretKey = true
            self.armored = privateArmored
            try update(db)
        }   // end let _ = try …
    }
    
}
