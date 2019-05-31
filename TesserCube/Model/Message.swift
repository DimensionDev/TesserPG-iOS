//
//  Message.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/30.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import GRDB

/// - Note: senderKeyId is lower 16 hex of primary signature key fingerprint. e.g. 58A8B23FAFB1E5C8
struct Message: Codable, FetchableRecord, MutablePersistableRecord, Equatable {
    var id: Int64?
    var senderKeyId: String         // a.k.a longIdentifier
    var senderKeyUserId: String
    var composedAt: Date?
    var interpretedAt: Date?
    var isDraft: Bool
    var rawMessage: String
    var encryptedMessage: String
    
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        if lhs.encryptedMessage == rhs.encryptedMessage {
            return true
        }
        return lhs.id == rhs.id
    }
}

/// - Note: keyId is lower 16 hex of primary signature key fingerprint. e.g. 58A8B23FAFB1E5C8
struct MessageRecipient: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var messageId: Int64
    var keyId: String       // a.k.a longIdentifier
    var keyUserId: String
    
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

extension Message {
    static let recipients = hasMany(MessageRecipient.self)
    var recipients: QueryInterfaceRequest<MessageRecipient> {
        return request(for: Message.recipients)
    }
}

extension MessageRecipient {
    func getKey() -> TCKey? {
        // Note: It's only guard the same primay signature key
        return ProfileService.default.keys.value.first { $0.longIdentifier == keyId }
    }
}
