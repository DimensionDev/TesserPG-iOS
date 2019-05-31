//
//  KeychainMappable.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-3-29.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation

// keychain save & retrieve
protocol KeychianMappable {
    var userID: String { get }  // public key userID
    var longIdentifier: String { get }
}

extension KeychianMappable {
    
    var shortIdentifier: String {
        return String(longIdentifier.suffix(8))
    }
    
}
