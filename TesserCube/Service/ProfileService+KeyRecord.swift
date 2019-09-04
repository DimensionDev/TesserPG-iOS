//
//  ProfileService+KeyRecord.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-9-3.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation

extension ProfileService {

    static func deleteKeyRecord(keyRecord: KeyRecord) throws {
        _ = try TCDBManager.default.dbQueue.write({ db in
            try keyRecord.delete(db)
        })
    }

}
