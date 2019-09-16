//
//  KeyRecordDBAction.swift
//  TesserCube
//
//  Created by jk234ert on 2019/4/2.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import DMSOpenPGP
import GRDB

extension KeyRecord {

    mutating func removeKeySecretPart() throws {
        guard let armored = armored else { return }
        guard let keyRing = try? DMSPGPKeyRing(armoredKey: armored) else {
            assertionFailure()
            return
        }
        let publicKeyArmored = keyRing.publicKeyRing.armored()

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

//    static func remove(keys: [String]) throws {
//        do {
//            _ = try TCDBManager.default.dbQueue.write({ db in
//                try KeyRecord.filter(keys.contains(Column("longIdentifier"))).deleteAll(db)
//            })
//        } catch let error {
//            throw error
//        }
//    }

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
