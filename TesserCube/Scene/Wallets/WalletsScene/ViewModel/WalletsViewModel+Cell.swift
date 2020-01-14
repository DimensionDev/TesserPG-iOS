//
//  WalletsViewModel+Cell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-10.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import Foundation

extension WalletsViewModel {
    
    // For WalletCardTableViewCell
    static func configure(cell: WalletCardTableViewCell, with model: WalletModel) {
        let address = model.address
        cell.walletCardView.headerLabel.text = String(address.prefix(6))
        cell.walletCardView.captionLabel.text = address
        // cell.captionLabel.text = {
        //     guard let address = address else { return nil }
        //     let raw = address.removingPrefix("0x")
        //     return "0x" + raw.prefix(20) + "\n" + raw.suffix(20)
        // }()
        model.balanceInDecimal.asDriver()
            .map { decimal in
                guard let decimal = decimal,
                    let decimalString = WalletService.balanceDecimalFormatter.string(from: decimal as NSNumber) else {
                        return "- ETH"
                }
                
                return decimalString + " ETH"
            }
            .drive(cell.walletCardView.balanceAmountLabel.rx.text)
            .disposed(by: cell.disposeBag)
    }
    
    // For WalletCardCollectionViewCell
    static func configure(cell: WalletCardCollectionViewCell, with model: WalletModel) {
        let address = model.address
        #if DEBUG
            #if MAINNET
            cell.walletCardView.headerLabel.text = String(address.prefix(6)) + " - Mainnet"
            #else
            cell.walletCardView.headerLabel.text = String(address.prefix(6)) + " - Rinkeby"
            #endif
        #else
        cell.walletCardView.headerLabel.text = String(address.prefix(6))
        #endif
        
        cell.walletCardView.captionLabel.text = address
        // cell.captionLabel.text = {
        //     guard let address = address else { return nil }
        //     let raw = address.removingPrefix("0x")
        //     return "0x" + raw.prefix(20) + "\n" + raw.suffix(20)
        // }()
        model.balanceInDecimal.asDriver()
            .map { decimal in
                guard let decimal = decimal,
                    let decimalString = WalletService.balanceDecimalFormatter.string(from: decimal as NSNumber) else {
                        return "- ETH"
                }
                
                return decimalString + " ETH"
            }
            .drive(cell.walletCardView.balanceAmountLabel.rx.text)
            .disposed(by: cell.disposeBag)
    }
    
}
