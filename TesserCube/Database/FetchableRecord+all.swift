//
//  FetchableRecord+all.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-9-10.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import GRDB

extension FetchableRecord where Self: TableRecord {

    static func all() -> [Self] {
        do {
            let all = try TCDBManager.default.dbQueue.read({ db in
                try fetchAll(db)
            })
            return all
        } catch {
            return []
        }
    }

}
