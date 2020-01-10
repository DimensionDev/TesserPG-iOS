//
//  RedPacketTokenSelectViewController.swift
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

protocol RedPacketTokenSelectViewControllerDelegate: class {
    func redPacketTokenSelectViewController(_ viewController: RedPacketTokenSelectViewController, didSelectTokenType selectTokenType: RedPacketTokenSelectViewModel.SelectTokenType)
}

final class RedPacketTokenSelectViewModel: NSObject {
    
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
            os_log("%{public}s[%{public}ld], %{public}s: RedPacketTokenSelectViewModel.init error: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
        }
    }
}

extension RedPacketTokenSelectViewModel {
    
    enum Section: CaseIterable {
        case eth
        case erc20
    }
    
    enum SelectTokenType {
        case eth
        case erc20(walletToken: WalletToken)
    }
}

extension RedPacketTokenSelectViewModel {
    
    static func configure(cell: TokenTableViewCell, with walletToken: WalletToken) {
        guard let token = walletToken.token else {
            return
        }
        
        cell.symbolLabel.text = token.symbol
        cell.nameLabel.text = token.name
        
        let balanceInDecimal = walletToken.balance
            .flatMap { Decimal(string: String($0)) }
            .map { decimal in decimal / pow(10, token.decimals) }
        
        let balanceInDecimalString: String? = balanceInDecimal.flatMap { decimal in
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumIntegerDigits = 1
            formatter.maximumFractionDigits = (token.decimals + 1) / 2
            formatter.groupingSeparator = ""
            return formatter.string(from: decimal as NSNumber)
        }
        cell.balanceLabel.text = balanceInDecimalString ?? "-"
    }
    
}

// MARK: - UITableViewDataSource
extension RedPacketTokenSelectViewModel: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section.allCases[section] {
        case .eth:
            return 1
        case .erc20:
            return tokens.value.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        switch Section.allCases[indexPath.section] {
        case .eth:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TokenTableViewCell.self), for: indexPath) as! TokenTableViewCell
            _cell.logoImageView.image = Asset.ethereumLogo.image
            _cell.symbolLabel.text = "ETH"
            _cell.nameLabel.text = "Ethereum"
            walletModel.balanceInDecimal.asDriver()
                .map { decimal in
                    guard let decimal = decimal,
                        let decimalString = WalletService.balanceDecimalFormatter.string(from: decimal as NSNumber) else {
                            return "-"
                    }
                    
                    return decimalString
                }
                .drive(_cell.balanceLabel.rx.text)
                .disposed(by: _cell.disposeBag)
            
            cell = _cell
            
        case .erc20:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TokenTableViewCell.self), for: indexPath) as! TokenTableViewCell
            let walletToken = tokens.value[indexPath.row]
            RedPacketTokenSelectViewModel.configure(cell: _cell, with: walletToken)
            
            cell = _cell
        }
        
        return cell
    }
    
}

final class RedPacketTokenSelectViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    var viewModel: RedPacketTokenSelectViewModel!
    
    weak var delegate: RedPacketTokenSelectViewControllerDelegate?
    
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(TokenTableViewCell.self, forCellReuseIdentifier: String(describing: TokenTableViewCell.self))
        return tableView
    }()

}

extension RedPacketTokenSelectViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Select Token"
        
        // Layout tableView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        // Setup tableView
        tableView.delegate = self
        tableView.dataSource = viewModel
        
        viewModel.tokens.asDriver()
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }
    
}

// MARK: - UITableViewDelegate
extension RedPacketTokenSelectViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch RedPacketTokenSelectViewModel.Section.allCases[indexPath.section] {
        case .eth:
            delegate?.redPacketTokenSelectViewController(self, didSelectTokenType: .eth)
        case .erc20:
            let walletToken = viewModel.tokens.value[indexPath.row]
            delegate?.redPacketTokenSelectViewController(self, didSelectTokenType: .erc20(walletToken: walletToken))
        }
    }
}

extension RedPacketTokenSelectViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
    
}
