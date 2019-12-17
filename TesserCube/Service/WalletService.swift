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
import DMS_HDWallet_Cocoa
import Web3

final public class WalletService {
    
    static let balanceDecimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumIntegerDigits = 1
        formatter.maximumFractionDigits = 4
        formatter.minimumFractionDigits = 1
        return formatter
    }()

    static let web3 = Web3(rpcURL: "https://rinkeby.infura.io/v3/823d2b1356e24d7fbd3b1ae954c6db19")
    static let chainID: EthereumQuantity = 4   // rinkeby

    private let keychain: Keychain
    private let disposeBag = DisposeBag()

    private let wallets: BehaviorRelay<[Wallet]>       // persistence to keychain, walletViewModels drives
    public let walletModels: BehaviorRelay<[WalletModel]>

    // MARK: - Singleton
    public static let `default` = WalletService(keychain: Keychain(service: "com.Sujitech.TesserCube", accessGroup: "7LFDZ96332.com.Sujitech.TesserCube"))

    private init(keychain: Keychain) {
        self.keychain = keychain

        let decoder = JSONDecoder()
        if let walletsData = keychain[data: "wallets"],
        let  walletsDatas = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(walletsData) as? [Data] {
            let wallets = (walletsDatas.compactMap { try? decoder.decode(Wallet.self, from: $0) })
            self.wallets = BehaviorRelay(value: wallets)
            let models = wallets.compactMap { try? WalletModel(wallet: $0) }
            self.walletModels = BehaviorRelay(value: models)
        } else {
            self.wallets = BehaviorRelay(value: [])
            self.walletModels = BehaviorRelay(value: [])
        }

        walletModels.asDriver()
            .map { $0.map { $0.wallet} }
            .drive(wallets)
            .disposed(by: disposeBag)

        wallets.asDriver()
            .drive(onNext: { [weak self] wallets in
                guard let `self` = self else { return }
                self.save()
            })
        .disposed(by: disposeBag)
    }

}

extension WalletService {

    private func save() {
        let encoder = JSONEncoder()
        let walletDatas = wallets.value.compactMap { try! encoder.encode($0) }

        do {
            let walletsData = try NSKeyedArchiver.archivedData(withRootObject: walletDatas, requiringSecureCoding: true)
            keychain[data: "wallets"] = walletsData
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

}

extension WalletService {

    // Only valid wallet appended
    func append(wallets: [Wallet]) {
        var models = walletModels.value
        let old = models.map { $0.wallet }
        let new = wallets.filter { !old.contains($0) }
        models.append(contentsOf: new.compactMap { try? WalletModel(wallet: $0) })
        walletModels.accept(models)
    }

    func append(wallet: Wallet) {
        append(wallets: [wallet])
    }

    func remove(wallet: Wallet) {
        let vms = walletModels.value.filter { $0.wallet != wallet }
        walletModels.accept(vms)
    }

}
