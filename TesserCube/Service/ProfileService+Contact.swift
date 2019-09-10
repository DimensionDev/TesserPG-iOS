//
//  ProfileService+Contact.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-9-10.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation

extension ProfileService {

    func addNewContact(keyUserID: String, key: TCKey) throws {
        do {
            let userInfo = PGPUserIDTranslator.extractMeta(from: keyUserID)
            let username = userInfo.name
            let email = userInfo.email
            guard username != nil || email != nil else {
                throw TCError.userInfoError(type: .invalidUserID(userID: keyUserID))
            }

            // contactsObervation will handle database update
            let _ = try TCDBManager.default.dbQueue.write { db -> Contact in
                var newContact = Contact(id: nil, name: username ?? "")
                try newContact.insert(db)
                if let contactId = newContact.id {
                    if let validMail = email {
                        var newEmail = Email(id: nil, address: validMail, contactId: contactId)
                        try newEmail.insert(db)
                    }
                    var newKeyRecord = KeyRecord(id: nil, longIdentifier: key.longIdentifier, hasSecretKey: key.hasSecretKey, hasPublicKey: key.hasPublicKey, contactId: contactId, armored: key.armored)
                    try newKeyRecord.insert(db)
                }
                return newContact
            }   // end let _ = try …

        } catch let error {
            throw error
        }
    }

    func deleteContact(_ contact: Contact) throws {
        do {
            guard let _ = contact.id else {
                assertionFailure("Entity without ID could not to delete")
                return
            }
            _ = try TCDBManager.default.dbQueue.write { db in
                try contact.delete(db)
            }

            // Any key records will be deleted cascade

        } catch let error {
            throw error
        }
    }

    func deleteContactSecretKey(_ contact: Contact) throws {
        guard let contactId = contact.id else { return }
        do {
            let keyRecords = contact.getKeyRecords()
            for keyRecord in keyRecords where keyRecord.hasSecretKey {
                var keyRecord = keyRecord
                try keyRecord.removeKeySecretPart()
            }
            ProfileService.default.contactChanged.accept([contactId])
        } catch {
            throw error
        }
    }

}
