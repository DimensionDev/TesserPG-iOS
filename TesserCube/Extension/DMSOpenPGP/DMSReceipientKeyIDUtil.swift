//
//  DMSReceipientKeyIDUtil.swift
//  TesserCube
//
//  Created by jk234ert on 2019/6/12.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation

extension Collection where Element == String {
    func containsHiddenRecipientKeyID() -> Bool {
        return contains { keyID -> Bool in
            return keyID.isHiddenRecipientID
        }
    }
    
    func trimHiddenRecipientKeyID() -> [Element] {
        return filter({ keyID -> Bool in
            return !keyID.isHiddenRecipientID
        })
    }
    
    func getNumberOfHiddenRecipientKeyIDs() -> Int {
        return count - trimHiddenRecipientKeyID().count
    }
}

extension String {
    var isHiddenRecipientID: Bool {
        return replacingOccurrences(of: "0", with: "").isEmpty
    }
}
