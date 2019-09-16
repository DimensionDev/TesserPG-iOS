//
//  KeyRecord.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-9-3.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import GRDB

struct KeyRecord: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var longIdentifier: String
    var hasSecretKey: Bool
    var hasPublicKey: Bool
    var contactId: Int64
    var armored: String?

    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
