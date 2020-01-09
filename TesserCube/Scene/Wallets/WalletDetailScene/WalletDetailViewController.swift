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
            if let token = walletToken.token {
                AddTokenViewModel.configure(cell: _cell, with: token)
            } else {
                assertionFailure()
            }
            cell = _cell
        }
                
        return cell
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
        case .token:
            return UIView() // TODO:
        default:
            return UIView()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch WalletDetailViewModel.Section.allCases[section] {
        case .token:
            return UITableView.automaticDimension
        default:
            return 10
        }
    }
    
    // Cell

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
            controller.dismiss(animated: true, completion: nil)
        } catch {
            let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            let okAction = UIAlertAction(title: L10n.Common.Button.ok, style: .default, handler: nil)
            alertController.addAction(okAction)
            controller.present(alertController, animated: true, completion: nil)
        }
    }
    
}
