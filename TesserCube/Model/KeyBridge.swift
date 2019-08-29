//
//  KeyBridge.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-4-2.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation

/// Bridge between Keychain and Contact base on PGPKey UserID & KeyID (longIdentifier)
struct KeyBridge: ContactMappable, KeychianMappable {

    let contact: Contact?
    let key: TCKey?

    let userID: String
    let longIdentifier: String

    var contactID: Int64? {
        return contact?.id
    }

    var name: String {
        let meta = DMSPGPUserIDTranslator(userID: userID)
        return contact?.name ?? meta.name ?? meta.email ?? ""
    }

    var shortID: String {
        return String(longIdentifier.suffix(8))
    }

    init(contact: Contact, key: TCKey) {
        self.contact = contact
        self.key = key
        self.userID = key.userID
        self.longIdentifier = key.longIdentifier
        assert(!self.longIdentifier.isEmpty)
    }

    // Key meta info stored in database
    // Should make sure key pass in or could restore by longIdentifier
    init(contact: Contact?, key: TCKey?, userID: String, longIdentifier: String) {
        let longIdentifier = key?.longIdentifier ?? longIdentifier
        assert(!longIdentifier.isEmpty)

        if let contact = contact {
            self.contact = contact
        } else {
            // restore contact if possiable
            // discard restored contact when multiple candidate
            let contacts = Contact.getOwnerContacts(longIdentifier: longIdentifier)
            self.contact = (contacts.count == 1) ? contacts.first : nil
        }
        if let key = key {
            self.key = key
        } else if let key = ProfileService.default.keys.value.first(where: { $0.longIdentifier == longIdentifier }) {   // restore key
            self.key = key
        } else {
            assertionFailure("key restore fail")
            self.key = nil
        }

        self.userID = key?.userID ?? userID
        self.longIdentifier = key?.longIdentifier ?? longIdentifier
    }
}
