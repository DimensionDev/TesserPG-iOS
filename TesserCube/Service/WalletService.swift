//
//  WalletService.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-8.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import Foundation
import RealmSwift
import RxSwift
import RxCocoa
import KeychainAccess
import DMS_HDWallet_Cocoa
import Web3

// Use keychain persist the mnemonic & password of the HDWallet
// The keychain data would not be clean except user erase the device
// Now we switch from the keychain model projection to realm DB model
//  1. check if alread saving data in keyPath "wallets"
//  2.a: if true and realm DB is empty: migrate all record in realm DB
//  2.b: else: do nothing and just fine
// And when insert a new wallet record:
// - insert to the keychain first then create the record in the realm DB
// And when remove the wallet record
// - remove the realm record then remove it from keychain
final public class WalletService {
    
    static let balanceDecimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumIntegerDigits = 1
        formatter.maximumFractionDigits = 4
        formatter.minimumFractionDigits = 1
        formatter.groupingSeparator = ""
        return formatter
    }()

    private let keychain: Keychain
    private let disposeBag = DisposeBag()

    private let wallets: BehaviorRelay<[Wallet]>       // persistence to keychain, walletViewModels drives
    public let walletModels: BehaviorRelay<[WalletModel]>
    
    static func realm() throws -> Realm {
        return try RealmService.realm()
    }

    // MARK: - Singleton
    public static let `default` = WalletService(keychain: Keychain(service: "com.Sujitech.TesserCube", accessGroup: "7LFDZ96332.com.Sujitech.TesserCube"))

    private init(keychain: Keychain) {
        self.keychain = keychain
        
        // let decoder = JSONDecoder()
        // if let walletsData = keychain[data: "wallets"],
        //     let walletsDatas = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(walletsData) as? [Data] {
        //     let wallets = (walletsDatas.compactMap { try? decoder.decode(Wallet.self, from: $0) })
        //     self.wallets = BehaviorRelay(value: wallets)
        //     let models = wallets.compactMap { try? WalletModel(wallet: $0) }
        //     self.walletModels = BehaviorRelay(value: models)
        // } else {
        //     self.wallets = BehaviorRelay(value: [])
        //     self.walletModels = BehaviorRelay(value: [])
        // }

        do {
            let decoder = JSONDecoder()
            
            let realm = try WalletService.realm()
            let walletObjectArray = Array(realm.objects(WalletObject.self))
            
            var walletModels: [WalletModel] = []
            for walletObject in walletObjectArray {
                guard let walletData = keychain[data: walletObject.address] else {
                    assertionFailure()
                    continue
                }
                guard let wallet = try? decoder.decode(Wallet.self, from: walletData) else {
                    assertionFailure()
                    continue
                }
                guard let walletModel = try? WalletModel(wallet: wallet) else {
                    assertionFailure()
                    continue
                }
                
                walletModels.append(walletModel)
            }
            
            self.walletModels = BehaviorRelay(value: walletModels)
            self.wallets = BehaviorRelay(value: walletModels.map { $0.wallet})
            
        } catch {
            self.walletModels = BehaviorRelay(value: [])
            self.wallets = BehaviorRelay(value: [])
        }

        self.walletModels.asDriver()
            .map { $0.map { $0.wallet} }
            .drive(wallets)
            .disposed(by: disposeBag)
    }

}

extension WalletService {

    // private func save() {
    //     let encoder = JSONEncoder()
    //     let walletDatas = wallets.value.compactMap { try! encoder.encode($0) }
    //
    //     do {
    //         let walletsData = try NSKeyedArchiver.archivedData(withRootObject: walletDatas, requiringSecureCoding: true)
    //         keychain[data: "wallets"] = walletsData
    //     } catch {
    //         assertionFailure(error.localizedDescription)
    //     }
    // }

}

extension WalletService {

    // Only valid wallet appended
    func append(wallets: [Wallet]) {
        var models = walletModels.value
        let old = models.map { $0.wallet }
        let new = wallets.filter { !old.contains($0) }
        
        let encoder = JSONEncoder()
        var newWalletModels: [WalletModel] = []
        for newWallet in new {
            guard let walletData = try? encoder.encode(newWallet) else {
                assertionFailure()
                continue
            }
            guard let hdWallet = try? HDWallet(mnemonic: newWallet.mnemonic, passphrase: newWallet.passphrase, network: .mainnet(.ether)),
            let walletAddress = try? hdWallet.address() else {
                assertionFailure()
                continue
            }
            keychain[data: walletAddress] = walletData
            
            guard let newWalletModel = try? WalletModel(wallet: newWallet) else {
                assertionFailure()
                continue
            }
            
            newWalletModels.append(newWalletModel)
        }

        models.append(contentsOf: newWalletModels)
        walletModels.accept(models)
    }

    func append(wallet: Wallet) {
        append(wallets: [wallet])
    }

    func remove(wallet: Wallet) {
        let removedWalletModel = walletModels.value.filter { $0.wallet == wallet }
        let removedWalletAddresses = removedWalletModel.map { $0.address }
        
        do {
            let realm = try WalletService.realm()
            try realm.write {
                realm.delete(removedWalletModel.map { $0.walletObject })
            }
            for walletAddressForRemove in removedWalletAddresses {
                keychain[data: walletAddressForRemove] = nil
            }
            
            let newWalletViewModels = walletModels.value.filter { $0.wallet != wallet }
            walletModels.accept(newWalletViewModels)
            
        } catch {
            os_log("%{public}s[%{public}ld], %{public}s: remove walletObject fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
        }
    }

}
