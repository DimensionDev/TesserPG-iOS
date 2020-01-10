//
//  WalletDetailViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-8.
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
            formatter.maximumFractionDigits = min(4, token.decimals)
            formatter.groupingSeparator = ""
            return formatter.string(from: decimal as NSNumber)
        }
        cell.balanceLabel.text = balanceInDecimalString ?? "-"
    }
    
}

final class WalletDetailViewController: TCBaseViewController {
    
    let disposeBag = DisposeBag()
    var viewModel: WalletDetailViewModel!
    
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(WalletCardTableViewCell.self, forCellReuseIdentifier: String(describing: WalletCardTableViewCell.self))
        tableView.register(TokenTableViewCell.self, forCellReuseIdentifier: String(describing: TokenTableViewCell.self))
        tableView.separatorStyle = .none
        return tableView
    }()
    
    lazy var walletSectionFooterView: UIView = {
        let stackView = UIStackView()
        
        stackView.preservesSuperviewLayoutMargins = true
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins.top = 10
        
        stackView.axis = .horizontal
        stackView.spacing = 15
        stackView.distribution = .fillEqually
        
        let copyAddressButton: TCActionButton = {
            let button = TCActionButton()
            button.color = .systemBlue
            button.setTitleColor(.white, for: .normal)
            button.setTitle("Copy Address", for: .normal)
            button.rx.tap.bind { [weak self] in
                guard let `self` = self else { return }
                UIPasteboard.general.string = self.viewModel.walletModel.address
            }
            .disposed(by: disposeBag)
            return button
        }()
        let addTokenButton: TCActionButton = {
            let button = TCActionButton()
            button.color = .systemBlue
            button.setTitleColor(.white, for: .normal)
            button.setTitle("Add Token", for: .normal)
            button.rx.tap.bind { [weak self] in
                guard let `self` = self else { return }
                let viewModel = AddTokenViewModel()
                Coordinator.main.present(scene: .addToken(viewModel: viewModel, delegate: self), from: self, transition: .modal, completion: nil)
            }
            .disposed(by: disposeBag)
            return button
        }()
        
        stackView.addArrangedSubview(copyAddressButton)
        stackView.addArrangedSubview(addTokenButton)
        
        return stackView
    }()
    
    let tokenSectionHeaderView: UIView = {
        let headerView = UIView()
        headerView.preservesSuperviewLayoutMargins = true
        
        let label = UILabel()
        
        label.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: headerView.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: headerView.layoutMarginsGuide.trailingAnchor),
            headerView.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
        ])
        
        label.textColor = ._secondaryLabel
        label.font = FontFamily.SFProText.regular.font(size: 13)
        label.text = "My Tokens"
        
        return headerView
    }()
    
    override func configUI() {
        super.configUI()
        
        title = "Wallet " + viewModel.walletModel.walletObject.name
        navigationItem.largeTitleDisplayMode = .never
        
        // Layout tableView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
        ])
        
        // Setup tableView data source
        tableView.delegate = self
        tableView.dataSource = viewModel
        
        viewModel.tokens.asDriver()
            .drive(onNext: { [weak self] _ in
                os_log("%{public}s[%{public}ld], %{public}s: tokens changed. reload tableView", ((#file as NSString).lastPathComponent), #line, #function)
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s: deinit", ((#file as NSString).lastPathComponent), #line, #function)

    }
    
}

// MARK: - UITableViewDelegate
extension WalletDetailViewController: UITableViewDelegate {
    
    // Header
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch WalletDetailViewModel.Section.allCases[section] {
        case .token where !viewModel.tokens.value.isEmpty:
            return tokenSectionHeaderView
        default:
            return UIView()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch WalletDetailViewModel.Section.allCases[section] {
        case .token where !viewModel.tokens.value.isEmpty:
            return UITableView.automaticDimension
        default:
            return 10
        }
    }
    
    // Cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch WalletDetailViewModel.Section.allCases[indexPath.section] {
        case .token:
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            break
        }
    }

    // Footer
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch WalletDetailViewModel.Section.allCases[section] {
        case .wallet:
            return walletSectionFooterView
        default:
            return UIView()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch WalletDetailViewModel.Section.allCases[section] {
        case .wallet:
            return UITableView.automaticDimension
        default:
            return 10
        }
    }
    
}

// MARK: - AddTokenViewControllerDelegate
extension WalletDetailViewController: AddTokenViewControllerDelegate {
    
    func addTokenViewController(_ controller: AddTokenViewController, didSelectToken token: ERC20Token) {
        do {
            let realm = try WalletService.realm()
            if realm.objects(WalletToken.self).filter("wallet.address == %@ && token.address == %@", viewModel.walletModel.address, token.address).first == nil {
                let index: Int = {
                    let tokens = realm.objects(WalletToken.self).filter("wallet.address == %@", viewModel.walletModel.address)
                    let maxIndex = tokens.max(ofProperty: "index") as Int?
                    return maxIndex ?? 0
                }()
                
                let walletToken = WalletToken()
                walletToken.wallet = viewModel.walletModel.walletObject
                walletToken.token = token
                walletToken.index = index
                
                try realm.write {
                    realm.add(walletToken)
                }
            }
            
            controller.dismiss(animated: true, completion: {
                // reload balance after new token inserted
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.viewModel.walletModel.updateBalance()
                }
            })
            
        } catch {
            let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            let okAction = UIAlertAction(title: L10n.Common.Button.ok, style: .default, handler: nil)
            alertController.addAction(okAction)
            controller.present(alertController, animated: true, completion: nil)
        }
    }
    
}
