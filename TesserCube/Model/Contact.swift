//
//  Contact.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/20.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import GRDB

struct Contact: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var name: String
    
    static func filter(name: String) -> QueryInterfaceRequest<Contact> {
        return filter(Column("name") == name)
    }
    
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

extension Contact {
    static let emails = hasMany(Email.self)
    var emails: QueryInterfaceRequest<Email> {
        return request(for: Contact.emails)
    }
}

extension Contact {
    static let keys = hasMany(KeyRecord.self)
    var keys: QueryInterfaceRequest<KeyRecord> {
        return request(for: Contact.keys)
    }
}
