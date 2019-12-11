//
//  ProfileService+Message.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/30.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import KeychainAccess
import ConsolePrint

extension ProfileService {
    
    
    /// Check armored message if already in database
    /// - Parameter encryptedMessage: armored PGP message
    func interptedMessage(_ encryptedMessage: String) -> Message? {
        let trimmedEncryptedMessage = encryptedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        return messages.value.first {
            $0.encryptedMessage.trimmingCharacters(in: .whitespacesAndNewlines) == trimmedEncryptedMessage
        }
    }
    
    // func containsMessage(_ message: Message) -> Bool {
    //     return messages.value.contains(message)
    // }
    
    @discardableResult
    func addMessage(_ message: inout Message, recipientKeys: [TCKey]) throws -> Message {
        do {
            let addedMessage = try TCDBManager.default.dbQueue.write({ db -> Message in
                try message.insert(db)
                guard let messageId = message.id else {
                    throw TCError.composeError(reason: .internal)
                }
                try recipientKeys.forEach {
                    var messageRecipient = MessageRecipient(id: nil, messageId: messageId, keyId: $0.longIdentifier, keyUserId: $0.userID)
                    try messageRecipient.insert(db)
                }
                return message
            })

            // Add red packet record into database if possible
            _ = RedPacketService.shared.redPacket(from: addedMessage)
            
            return addedMessage
            
        } catch let error {
            consolePrint(error.localizedDescription)
            throw error
        }
    }
    
    func delete(messages: [Message]) {
        do {
            _ = try TCDBManager.default.dbQueue.write { db in
                for message in messages {
                    try message.delete(db)
                }
            }
        } catch let error {
            consolePrint(error.localizedDescription)
            return
        }
    }

}

extension ProfileService {

    /// Encrypt message and store in database
    ///
    /// - Parameter message: raw message
    /// - Returns: Message
    func encryptMessage(_ message: String, signatureKey: TCKey?, recipients: [TCKey]) throws -> Message {
        do {
            guard !message.isEmpty else {
                throw TCError.interpretError(reason: .emptyMessage)
            }

            let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
            let encrypted = try KeyFactory.encryptMessage(message, signatureKey: signatureKey, recipients: recipients)

            var message = Message(id: nil,
                                  senderKeyId: signatureKey?.longIdentifier ?? "",
                                  senderKeyUserId: signatureKey?.userID ?? "",
                                  composedAt: Date(),
                                  interpretedAt: nil,
                                  isDraft: false,
                                  rawMessage: trimmedMessage,
                                  encryptedMessage: encrypted)

            try ProfileService.default.addMessage(&message, recipientKeys: recipients)
            return message
        } catch {
            consolePrint(error.localizedDescription)
            throw error
        }
    }

    /// Decrypt message and store in database
    ///
    /// - Parameter message: armored message
    /// - Returns: Message
    func decryptMessage(_ message: String) throws -> Message {
        do {
            guard !message.isEmpty else {
                throw TCError.interpretError(reason: .emptyMessage)
            }
                        
            // Check if message already interpreted
            if var existMessage = interptedMessage(message) {
                // If yes, just return the message
                try existMessage.updateInterpretedDate(Date())
                return existMessage
            }

            var senderKeyID = ""
            var senderKeyUserID = ""
            let decryptInfo = try KeyFactory.decryptMessage(message)
            switch decryptInfo.verifyResult {
            case .noSignature:
                break
            case .valid, .invalid:
                senderKeyID = decryptInfo.signatureKey?.longIdentifier ?? ""
                senderKeyUserID = decryptInfo.signatureKey?.userID ?? ""
            case .unknownSigner(let infos):
                // This is real KeyID of signature key (not long identifier)
                // TODO: Get signer userID in DMSGoPGP
                senderKeyID = infos.first?.keyID ?? ""
                senderKeyUserID = infos.first?.primaryUserID ?? ""
            }

            var interpretedMessage = Message(id: nil,
                                             senderKeyId: senderKeyID,
                                             senderKeyUserId: senderKeyUserID,
                                             composedAt: nil,
                                             interpretedAt: Date(),
                                             isDraft: false,
                                             rawMessage: decryptInfo.message,
                                             encryptedMessage: message)
            
            try ProfileService.default.addMessage(&interpretedMessage, recipientKeys: decryptInfo.recipientKeys)
            return interpretedMessage
        } catch let error {
            consolePrint(error.localizedDescription)
            throw error
        }
    }
}
