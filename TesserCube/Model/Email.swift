//
//  Email.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-9-3.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import GRDB

struct Email: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var address: String
    var contactId: Int64

    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
