//
//  WalletService.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-8.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import RxSwift
import RxCocoa
import KeychainAccess

final public class WalletService {

    private let wallets = BehaviorRelay<[Wallet]>(value: [])        // persistence to keychain, drived by walletViewModels
    public let walletModels = BehaviorRelay<[WalletViewModel]>(value: [])

    // MARK: - Singleton
    public static let `default` = WalletService()

    private init() {

    }

}

public struct Wallet: Codable {
    public let mnemonic: [String]
    public let passphrase: String
    // …
}

public class WalletViewModel {
    let wallet: Wallet
    // let balance = BehaviorRelay<BigUInt>(value: BigUInt(0))

    public init(wallet: Wallet) {
        self.wallet = wallet
    }
}
