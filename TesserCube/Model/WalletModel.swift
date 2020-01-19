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
    let currentEthereumNetwork = BehaviorRelay(value: EthereumPreference.ethereumNetwork)
    private let updateBalanceTrigger = PublishSubject<Void>()

    // Output
    
    // ETH balance
    let mainnetBalance = BehaviorRelay<BigUInt?>(value: nil)
    let rinkebyBalance = BehaviorRelay<BigUInt?>(value: nil)
    let ropstenBalance = BehaviorRelay<BigUInt?>(value: nil)
    let balance = BehaviorRelay<BigUInt?>(value: nil)
    let balanceInDecimal: Driver<Decimal?>

    // Misc.
    let hdWallet: HDWallet
    let address: String
    let walletObject: WalletObject
    
    private var currentEthereumNetworkObserver: NSKeyValueObservation?

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

        Driver.combineLatest(currentEthereumNetwork.asDriver(), mainnetBalance.asDriver(), rinkebyBalance.asDriver(), ropstenBalance.asDriver()) { (network, mainnetBalance, rinkebyBalance, ropstenBalance) -> BigUInt? in
            switch network {
            case .mainnet:  return mainnetBalance
            case .rinkeby:  return rinkebyBalance
            case .ropsten:  return ropstenBalance
            }
        }
        .drive(balance)
        .disposed(by: disposeBag)
    
        balanceInDecimal = balance.asDriver()
            .map { balance in
                guard let balance = balance else { return nil }
                return (Decimal(string: String(balance)) ?? Decimal(0)) / HDWallet.CoinType.ether.exponent
            }

        defer {
            currentEthereumNetworkObserver = UserDefaults.shared!.observe(\.ethereumNetwork, options: [.initial, .new]) { [weak self] userDefaults, change in
                self?.currentEthereumNetwork.accept(EthereumPreference.ethereumNetwork)
            }
            self.mainnetBalance.accept(walletObject.balance)
            self.rinkebyBalance.accept(walletObject.rinkeby_balance)
            self.ropstenBalance.accept(walletObject.ropsten_balance)
            updateBalance()
        }

        // setup
        // update mainnet
        Observable.combineLatest(currentEthereumNetwork.asObservable(), updateBalanceTrigger.asObserver())
            .filter { $0.0 == .mainnet }
            .flatMapLatest { _ in WalletService.getBalance(for: self.address, web3: Web3Secret.web3(for: .mainnet)).asObservable() }
            .subscribe(onNext: { [weak self] balance in     // ignore error case
                guard let `self` = self else { return }
                
                self.mainnetBalance.accept(balance)
                
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
        
        // update ropsten
        Observable.combineLatest(currentEthereumNetwork.asObservable(), updateBalanceTrigger.asObserver())
            .filter { $0.0 == .ropsten }
            .flatMapLatest { _ in WalletService.getBalance(for: self.address, web3: Web3Secret.web3(for: .ropsten)).asObservable() }
            .subscribe(onNext: { [weak self] balance in     // ignore error case
                guard let `self` = self else { return }
                

                self.ropstenBalance.accept(balance)
                
                // Update walletObject balance
                do {
                    let realm = try WalletService.realm()
                    guard let walletObject = realm.objects(WalletObject.self).filter("address == %@", self.address).first else {
                        return
                    }
                    try realm.write {
                        walletObject.ropsten_balance = balance
                    }
                    
                } catch {
                    os_log("%{public}s[%{public}ld], %{public}s: update walletObject balance fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                }
            })
            .disposed(by: disposeBag)
        
        // update rinkeby
        Observable.combineLatest(currentEthereumNetwork.asObservable(), updateBalanceTrigger.asObserver())
            .filter { $0.0 == .rinkeby }
            .flatMapLatest { _ in WalletService.getBalance(for: self.address, web3: Web3Secret.web3(for: .rinkeby)).asObservable() }
            .subscribe(onNext: { [weak self] balance in     // ignore error case
                guard let `self` = self else { return }
                
                self.rinkebyBalance.accept(balance)
                
                // Update walletObject balance
                do {
                    let realm = try WalletService.realm()
                    guard let walletObject = realm.objects(WalletObject.self).filter("address == %@", self.address).first else {
                        return
                    }
                    try realm.write {
                        walletObject.rinkeby_balance = balance
                    }
                    
                } catch {
                    os_log("%{public}s[%{public}ld], %{public}s: update walletObject balance fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                }
            })
            .disposed(by: disposeBag)
        
        let walletID = walletObject.id
        let walletAddress = self.address
        
        // update wallet tokens
        updateBalanceTrigger.asObserver()
            .withLatestFrom(currentEthereumNetwork.asObservable())
            .flatMapLatest { currentEthereumNetwork -> Observable<Result<(String, BigUInt), Error>> in
                do {
                    let realm = try WalletService.realm()
                    let result = realm.objects(WalletToken.self).filter("wallet.id == %@", walletID)
                        .sorted(by: { (lhs, rhs) -> Bool in
                            if (lhs._token_balance ?? "").isEmpty || (rhs._token_balance ?? "").isEmpty {
                                return true
                            }
                            
                            return false
                        })
                        .compactMap { walletToken -> (String, EthereumNetwork)? in
                            guard let token = walletToken.token else { return nil }
                            guard token.network == currentEthereumNetwork else { return nil }
                            return (token.address, token.network)
                        }
                    let tokenAddressWithNetworks = Array(result)
                    
                    return Observable.from(tokenAddressWithNetworks)
                        .map { (tokenAddress, network) -> Observable<Result<(String, BigUInt), Error>> in
                            os_log("%{public}s[%{public}ld], %{public}s: update token %s balance", ((#file as NSString).lastPathComponent), #line, #function, tokenAddress)

                            let web3 = Web3Secret.web3(for: network)
                            return WalletService.getERC20TokenBalance(forWallet: walletAddress, ofContract: tokenAddress, web3: web3)
                                .map { balance in (tokenAddress, balance) }
                                .map { Result<(String, BigUInt), Error>.success($0)}
                                .asObservable()
                                .catchErrorJustReturn(Result.failure(WalletService.Error.invalidAmount))
                        }
                        .merge(maxConcurrent: 1)    // make task execute in sequence
                    
                } catch {
                    return Observable.just(Result.failure(error))
                }
            }
            .subscribe(onNext: { result in
                switch result {
                case let .success(tuple):
                    let (tokenAddress, balance) = tuple
                    os_log("%{public}s[%{public}ld], %{public}s: update token %s balance %s", ((#file as NSString).lastPathComponent), #line, #function, tokenAddress, String(balance))

                    do {
                        let realm = try WalletService.realm()
                        guard let walletToken = realm.objects(WalletToken.self).filter("wallet.id == %@ && token.address == %@", walletID, tokenAddress).first else {
                            return
                        }
                        try realm.write {
                            walletToken.balance = balance
                        }
                    } catch {
                        os_log("%{public}s[%{public}ld], %{public}s: update token balance error: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    }
                    
                case let .failure(error):
                    os_log("%{public}s[%{public}ld], %{public}s: erc20 fetch balance error: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                }
            }, onError: { _ in
                assertionFailure()
            }, onDisposed: {
                os_log("%{public}s[%{public}ld], %{public}s: token update disposed", ((#file as NSString).lastPathComponent), #line, #function)
                
            })
            .disposed(by: disposeBag)
    }
    
    deinit {
        currentEthereumNetworkObserver?.invalidate()
    }

}

extension WalletModel {

    func updateBalance() {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
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
