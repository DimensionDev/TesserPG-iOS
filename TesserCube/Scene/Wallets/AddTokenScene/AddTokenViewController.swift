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

protocol AddTokenViewControllerDelegate: class {
    func addTokenViewController(_ controller: AddTokenViewController, didSelectToken token: ERC20Token)
}

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
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s: deinit", ((#file as NSString).lastPathComponent), #line, #function)

    }
    
}

extension AddTokenViewModel {
    
    func addToken(token: ERC20Token) {
        
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
        cell.balanceLabel.text = ""
    }
    
}

final class AddTokenViewController: TCBaseViewController {
    
    let disposeBag = DisposeBag()
    var viewModel: AddTokenViewModel!
    
    weak var delegate: AddTokenViewControllerDelegate?

    private weak var searchController: UISearchController?
    
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
    
    private(set) lazy var customTokenBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(title: "Custom Token", style: .plain, target: self, action: #selector(AddTokenViewController.customTokenBarButtonItemPressed(_:)))
        return barButtonItem
    }()
    
    override func configUI() {
        super.configUI()
        
        let searchController: UISearchController = {
            let controller = UISearchController(searchResultsController: nil)
            controller.obscuresBackgroundDuringPresentation = false
            controller.hidesNavigationBarDuringPresentation = false
            controller.delegate = self
            controller.searchBar.delegate = self
            controller.searchResultsUpdater = self
            
            return controller
        }()
        self.searchController = searchController
        
        title = "Add Token"
        navigationItem.leftBarButtonItem = closeBarButtonItem
        navigationItem.rightBarButtonItem = customTokenBarButtonItem
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

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
        
        searchController.searchBar.rx.text.orEmpty
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(viewModel.searchText)
            .disposed(by: disposeBag)
        
        // Setup notification
        NotificationCenter.default.addObserver(self, selector: #selector(AddTokenViewController.keyboardWillShowNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AddTokenViewController.keyboardWillHideNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        os_log("%{public}s[%{public}ld], %{public}s: deinit", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension AddTokenViewController {
    
    override func viewWillDisappear(_ animated: Bool) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        super.viewWillDisappear(animated)

        searchController?.isActive = false
    }
    
}

extension AddTokenViewController {
    
    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        searchController?.isActive = false
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func customTokenBarButtonItemPressed(_ sender: UIBarButtonItem) {
        let viewModel = CustomTokenViewModel()
        Coordinator.main.present(scene: .customToken(viewModel: viewModel, delegate: self), from: self, transition: .detail, completion: nil)
    }
    
}

// MARK: - UITableViewDelegate
extension AddTokenViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let token = viewModel.filteredTokens.value[indexPath.row]

        delegate?.addTokenViewController(self, didSelectToken: token)
        os_log("%{public}s[%{public}ld], %{public}s: did select token - %s", ((#file as NSString).lastPathComponent), #line, #function, token.name)
        // delegate control dismiss
    }
    
}

// MARK: - UISearchControllerDelegate
extension AddTokenViewController: UISearchControllerDelegate {
    
}

// MARK: - UISearchBarDelegate
extension AddTokenViewController: UISearchBarDelegate {
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.searchText.accept("")     // reset search text when cancel searching
    }
    
}

// MARK: - UISearchResultsUpdating
extension AddTokenViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

    }
    
}

extension AddTokenViewController {
    
    @objc private func keyboardWillShowNotification(_ notification: Notification) {
        guard let endFrame = notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? CGRect else {
            return
        }
        
        // Keyboard only display in search mode
        tableView.contentInset.bottom = endFrame.height
        tableView.scrollIndicatorInsets.bottom = endFrame.height - view.safeAreaInsets.bottom
    }
    
    @objc private func keyboardWillHideNotification(_ notification: Notification) {
        // back to normal mode
        tableView.contentInset.bottom = 0
        tableView.scrollIndicatorInsets.bottom = 0
    }
    
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension AddTokenViewController: UIAdaptivePresentationControllerDelegate {
    
}

// MARK: - CustomTokenViewControllerDelegate
extension AddTokenViewController: CustomTokenViewControllerDelegate {
    
}
