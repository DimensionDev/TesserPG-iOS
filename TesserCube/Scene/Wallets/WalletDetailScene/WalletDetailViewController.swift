//
//  WalletDetailViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-8.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import os
import UIKit
import RxSwift
import RxCocoa

final class WalletDetailViewModel: NSObject {
    
    // Input
    let walletModel: WalletModel
    
    // Output
    
    init(walletModel: WalletModel) {
        self.walletModel = walletModel
        super.init()
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
        case .token:    return 0
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
            fatalError()
            break
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
                Coordinator.main.present(scene: .addToken(viewModel: viewModel), from: self, transition: .modal, completion: nil)
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
        
        title = "Red Packet Detail"
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
