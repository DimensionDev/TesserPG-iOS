//
//  WalletValue.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-13.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import Foundation
import DMS_HDWallet_Cocoa

public struct WalletValue {
    
    let wallet: Wallet
    let hdWallet: HDWallet
    let address: String
    
    init(from walletModel: WalletModel) {
        self.wallet = walletModel.wallet
        self.hdWallet = walletModel.hdWallet
        self.address = walletModel.address
    }
    
}
