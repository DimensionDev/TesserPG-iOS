//
//  WalletModel.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-13.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
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
    let walletObject: WalletObject

    public init(wallet: Wallet) throws {
        self.wallet = wallet
        self.hdWallet = try HDWallet(mnemonic: wallet.mnemonic, passphrase: wallet.passphrase, network: .mainnet(.ether))
        let _address = try hdWallet.address()
        self.address = _address
        
        // Retrive walletObject or create if not exists
        let realm = try WalletService.realm()
        if let walletObject = realm.objects(WalletObject.self).filter("address == %@", _address).first {
            self.walletObject = walletObject
        } else {
            let walletObject = WalletObject()
            walletObject.address = _address
            walletObject.name = String(_address.prefix(6))
            try realm.write {
                realm.add(walletObject)
            }
            self.walletObject = walletObject
        }
    
        balanceInDecimal = balance.asDriver()
            .map { balance in
                guard let balance = balance else { return nil }
                return (Decimal(string: String(balance)) ?? Decimal(0)) / HDWallet.CoinType.ether.exponent
            }

        defer {
            balance.accept(walletObject.balance)
            updateBalance()
        }

        // setup
        updateBalanceTrigger.asObserver()
            .flatMapLatest { WalletService.getBalance(for: self.address).asObservable() }
            .subscribe(onNext: { [weak self] balance in     // ignore error case
                guard let `self` = self else { return }
                
                self.balance.accept(balance)
                
                // Update walletObject balance
                do {
                    let realm = try WalletService.realm()
                    guard let walletObject = realm.objects(WalletObject.self).filter("address == %@", self.address).first else {
                        return
                    }
                    try realm.write {
                        walletObject.balance = balance
                    }
                    
                } catch {
                    os_log("%{public}s[%{public}ld], %{public}s: update walletObject balance fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)

                }
            })
            .disposed(by: disposeBag)
    }

}

extension WalletModel {

    func updateBalance() {
        updateBalanceTrigger.onNext(())
    }

}

extension WalletModel: Equatable {
    
    public static func == (lhs: WalletModel, rhs: WalletModel) -> Bool {
        return lhs.wallet.mnemonic == rhs.wallet.mnemonic &&
               lhs.wallet.passphrase == rhs.wallet.passphrase
    }
    
}

extension WalletModel: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(wallet.mnemonic)
        hasher.combine(wallet.passphrase)
    }
    
}