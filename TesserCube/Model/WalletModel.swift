//
//  WalletModel.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-13.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import BigInt
import DMS_HDWallet_Cocoa

public class WalletModel {

    private let disposeBag = DisposeBag()

    // Input
    let wallet: Wallet
    private let updateBalanceTrigger = PublishSubject<Void>()

    // Output
    let balance = BehaviorRelay<BigUInt?>(value: nil)
    let balanceInDecimal: Driver<Decimal?>

    // Misc.
    let hdWallet: HDWallet
    let address: String

    public init(wallet: Wallet) throws {
        self.wallet = wallet
        self.hdWallet = try HDWallet(mnemonic: wallet.mnemonic, passphrase: wallet.passphrase, network: .mainnet(.ether))
        self.address = try hdWallet.address()

        balanceInDecimal = balance.asDriver()
            .map { balance in
                guard let balance = balance else { return nil }
                return (Decimal(string: String(balance)) ?? Decimal(0)) / HDWallet.CoinType.ether.exponent
            }

        defer {
            updateBalance()
        }

        // setup
        updateBalanceTrigger.asObserver()
            .flatMapLatest { WalletService.getBalance(for: self.address).asObservable() }
            .asDriver(onErrorJustReturn: BigUInt(0))
            .drive(balance)
            .disposed(by: disposeBag)
    }

}

extension WalletModel {

    func updateBalance() {
        updateBalanceTrigger.onNext(())
    }

}
