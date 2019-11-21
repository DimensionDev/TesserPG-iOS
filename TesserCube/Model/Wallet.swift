//
//  Wallet.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-13.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation

public struct Wallet: Codable {
    public let mnemonic: [String]
    public let passphrase: String
}

extension Wallet: Equatable {
    public static func == (lhs: Wallet, rhs: Wallet) -> Bool {
        return lhs.mnemonic == rhs.mnemonic && lhs.passphrase == rhs.passphrase
    }
}
