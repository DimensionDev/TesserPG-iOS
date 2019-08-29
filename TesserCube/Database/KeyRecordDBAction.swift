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

    static func remove(keys: [String]) throws {
        do {
            _ = try TCDBManager.default.dbQueue.write({ db in
                try KeyRecord.filter(keys.contains(Column("longIdentifier"))).deleteAll(db)
            })
        } catch let error {
            throw error
        }
    }

}
