//
//  MessageDBAction.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/31.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import GRDB

extension Message {

    static func loadMessage(id: Int64) -> Message? {
        do {
            return try TCDBManager.default.dbQueue.read { db in
                try Message.fetchOne(db, key: id)
            }
        } catch {
            return nil
        }
    }

    func getRecipients() -> [MessageRecipient] {
        let recipients = try? TCDBManager.default.dbQueue.read({ db in
            try self.recipients.fetchAll(db)
        })
        return recipients ?? []
    }

}

extension Message {
    
    mutating func updateInterpretedDate(_ date: Date) throws {
        do {
            try TCDBManager.default.dbQueue.write({ db in
                self.interpretedAt = date
                try update(db)
            })
        } catch let error {
            throw error
        }
    }

    mutating func updateDraftMessage(senderKeyID: String, senderKeyUserID: String, rawMessage: String, recipients: [TCKey], isDraft: Bool = true, armoredMessage: String? = nil) throws {
        assert(self.isDraft)
        assert((isDraft && armoredMessage == nil) || (!isDraft && armoredMessage != nil))

        let oldMessageRecipients = self.getRecipients()

        do {
            try TCDBManager.default.dbQueue.write { db in
                self.senderKeyId = senderKeyID
                self.senderKeyUserId = senderKeyUserID
                self.rawMessage = rawMessage
                self.isDraft = isDraft

                if !isDraft {
                    guard let encryptedMessage = armoredMessage, !encryptedMessage.isEmpty else {
                        throw TCError.composeError(reason: TCError.ComposeErrorReason.internal)
                    }
                    self.encryptedMessage = encryptedMessage
                    // Update composeAt date
                    self.composedAt = Date()
                    self.interpretedAt = nil
                } else {
                    self.encryptedMessage = ""
                    // Use interpretedAt date as lastUpdate date
                    self.interpretedAt = Date()
                }

                guard let messageID = self.id else {
                    throw TCError.composeError(reason: .internal)
                }
                let newMessageRecipients = recipients.map { MessageRecipient(id: nil, messageId: messageID, keyId: $0.longIdentifier, keyUserId: $0.userID)}

                let recipientsToDelete = oldMessageRecipients.filter { old in
                    !newMessageRecipients.contains(where: { new in old.keyId == new.keyId })
                }
                let recipientsToInsert = newMessageRecipients.filter { new in
                    !oldMessageRecipients.contains(where: { old in old.keyId == new.keyId })
                }
                try recipientsToDelete.forEach { messageRecipient in
                    try messageRecipient.delete(db)
                }
                try recipientsToInsert.forEach { messageRecipient in
                    var messageRecipient = messageRecipient
                    try messageRecipient.insert(db)
                }

                try update(db)
            }
        } catch {
            throw error
        }
    }

}
