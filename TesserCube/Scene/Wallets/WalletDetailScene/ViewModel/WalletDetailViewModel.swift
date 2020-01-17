//
//  WalletDetailViewModel.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-10.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import os
import UIKit
import RealmSwift
import RxSwift
import RxCocoa
import RxRealm

final class WalletDetailViewModel: NSObject {
    
    let disposeBag = DisposeBag()
    
    // Input
    let walletModel: WalletModel
    
    // Output
    let tokens = BehaviorRelay<[WalletToken]>(value: [])
    
    init(walletModel: WalletModel) {
        self.walletModel = walletModel
        
        super.init()
        
        // Setup tokens data
        do {
            let realm = try WalletService.realm()
            let tokens = realm.objects(WalletToken.self)
                .filter("wallet.address == %@", walletModel.address)
                .sorted(byKeyPath: "index", ascending: true)
            Observable.array(from: tokens)
                .subscribe(onNext: { [weak self] tokens in
                    guard let `self` = self else { return }
                    self.tokens.accept(tokens)
                })
                .disposed(by: disposeBag)
        } catch {
            os_log("%{public}s[%{public}ld], %{public}s: WalletDetailViewModel.init error: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
        }
    }
    
}

extension WalletDetailViewModel {
    
    enum Section: Int, CaseIterable {
        case wallet
        case token
    }
    
}

// MARK: - UITableViewDataSource
extension WalletDetailViewModel: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section.allCases[section] {
        case .wallet:   return 1
        case .token:    return tokens.value.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        switch Section.allCases[indexPath.section] {
        case .wallet:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: WalletCardTableViewCell.self), for: indexPath) as! WalletCardTableViewCell
            WalletsViewModel.configure(cell: _cell, with: walletModel)
            
            cell = _cell
        case .token:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TokenTableViewCell.self), for: indexPath) as! TokenTableViewCell
            let walletToken = tokens.value[indexPath.row]
            WalletDetailViewModel.configure(cell: _cell, with: walletToken)
            
            cell = _cell
            
            // Setup cell separator line
            UITableView.removeSeparatorLine(for: cell)
            
            let isFirst = indexPath.row == 0
            if isFirst {
                UITableView.setupTopSectionSeparatorLine(for: cell)
            }
            
            let isLast = indexPath.row == tokens.value.count - 1
            if isLast {
                UITableView.setupBottomSectionSeparatorLine(for: cell)
            } else {
                UITableView.setupBottomCellSeparatorLine(for: cell)
            }
            
        }
        
        return cell
    }
    
}

extension WalletDetailViewModel {
    
    static func configure(cell: TokenTableViewCell, with walletToken: WalletToken) {
        // fix target membership compile issue
        RedPacketTokenSelectViewModel.configure(cell: cell, with: walletToken)
    }
    
}

extension WalletDetailViewModel {
    
    func removeToken(at indexPath: IndexPath) -> Bool {
        let token = self.tokens.value[indexPath.row]
        
        do {
            let realm = try WalletService.realm()
            try realm.write {
                realm.delete(token)
            }
            
            return true
        } catch {
            return false
        }
        
    }
    
}
