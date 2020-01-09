//
//  AddTokenViewController.swift
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

final class AddTokenViewModel: NSObject {
    
    let disposeBag = DisposeBag()
    
    // Input
    var tokens = BehaviorRelay<[ERC20Token]>(value: [])
    var searchText = BehaviorRelay(value: "")
    
    // Output
    var filteredTokens = BehaviorRelay<[ERC20Token]>(value: [])
    
    override init() {
        super.init()
        
        Driver.combineLatest(tokens.asDriver(), searchText.asDriver()) { tokens, searchText -> [ERC20Token] in
                guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    return tokens
                }
                
                return tokens.filter { token -> Bool in
                    return token.address.contains(searchText) ||
                           token.name.contains(searchText) ||
                           token.symbol.contains(searchText)
                }
            }
            .drive(filteredTokens)
            .disposed(by: disposeBag)
    }
}

// MARK: - UITableViewDataSource
extension AddTokenViewModel: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTokens.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TokenTableViewCell.self), for: indexPath) as! TokenTableViewCell
        let token = filteredTokens.value[indexPath.row]
        AddTokenViewModel.configure(cell: cell, with: token)
        return cell
    }
    
}

extension AddTokenViewModel {
    
    static func configure(cell: TokenTableViewCell, with token: ERC20Token) {
        cell.symbolLabel.text = token.symbol
        cell.nameLabel.text = token.name
    }
    
}

final class AddTokenViewController: TCBaseViewController {
    
    let disposeBag = DisposeBag()
    var viewModel: AddTokenViewModel!
    
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(TokenTableViewCell.self, forCellReuseIdentifier: String(describing: TokenTableViewCell.self))
        tableView.tableHeaderView = {
            let headerView = UIView()
            headerView.frame.size.height = CGFloat.leastNonzeroMagnitude
            return headerView
        }()
        return tableView
    }()
    
    private(set) lazy var closeBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem.close
        barButtonItem.addTargetForAction(self, action: #selector(AddTokenViewController.closeBarButtonItemPressed(_:)))
        return barButtonItem
    }()
    
    override func configUI() {
        super.configUI()
        
        title = "Add Token"
        navigationItem.leftBarButtonItem = closeBarButtonItem
    
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
        
        // Setup view model
        do {
            let realm = try RedPacketService.realm()
            #if MAINNET
            let network = EthereumNetwork.mainnet.rawValue
            #else
            let network = EthereumNetwork.rinkeby.rawValue
            #endif
            
            let tokens = realm.objects(ERC20Token.self).filter("_network == %@", network).sorted(byKeyPath: "symbol", ascending: true)
            Observable.array(from: tokens)
                .subscribe(onNext: { [weak self] tokens in
                    self?.viewModel.tokens.accept(tokens)
                })
                .disposed(by: disposeBag)
        } catch {
            os_log("%{public}s[%{public}ld], %{public}s: setup viewModel fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)

        }
        
        viewModel.filteredTokens.asDriver()
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }
    
}

extension AddTokenViewController {
    
    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - UITableViewDelegate
extension AddTokenViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let token = viewModel.filteredTokens.value[indexPath.row]
        os_log("%{public}s[%{public}ld], %{public}s: did select token - %s", ((#file as NSString).lastPathComponent), #line, #function, token.name)

    }
    
}
