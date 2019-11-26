//
//  FullContactInfo.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-26.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation

struct FullContactInfo: Equatable {
    
    var contact: Contact
    var emails: [Email]
    var keys: [TCKey]
    
    static func == (lhs: FullContactInfo, rhs: FullContactInfo) -> Bool {
        return lhs.contact.id == rhs.contact.id
    }
}
