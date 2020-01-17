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
import Kingfisher

protocol AddTokenViewControllerDelegate: class {
    func addTokenViewController(_ controller: AddTokenViewController, didSelectToken token: ERC20Token)
}

final class AddTokenViewModel: NSObject {
    
    let disposeBag = DisposeBag()
    weak var customTokenViewControllerDelegate: CustomTokenViewControllerDelegate?
    
    // Input
    var tokens = BehaviorRelay<[ERC20Token]>(value: [])
    var searchText = BehaviorRelay(value: "")
    
    // Output
    var trie = BehaviorRelay(value: Trie<Character>())
    var filteredTokens = BehaviorRelay<[ERC20Token]>(value: [])
    
    init(customTokenViewControllerDelegate: CustomTokenViewControllerDelegate?) {
        self.customTokenViewControllerDelegate = customTokenViewControllerDelegate
        super.init()
        
        // Subscribe on background thread to avoid blocking the main thread
        Driver.combineLatest(trie.asDriver(), tokens.asDriver(), searchText.asDriver())
            .map { trie, tokens, searchText -> [ERC20Token] in
                let searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard !searchText.isEmpty else {
                    return tokens
                }
                
                guard !trie.children.isEmpty else {
                    return tokens.filter { token in token.symbol.localizedCaseInsensitiveContains(searchText) }
                }
                
                var filteredTokens: [ERC20Token] = []
                let passthroughs = trie.passthrough(ArraySlice(searchText.charactersArray))
                let symbolBestMatchIDs = passthroughs
                    .map { $0.values } // [Set<ID>]
                    .map { set in set.compactMap { $0 as? String } } // [[ID]]
                    .flatMap { $0 } // [ID]
                let symbolBestMatchIDSet = Set(symbolBestMatchIDs)
                let targetTokens = tokens.filter { symbolBestMatchIDSet.contains($0.id) }
                
                filteredTokens.append(contentsOf: symbolBestMatchIDSet
                    .compactMap { id in targetTokens.first(where: { $0.id == id}) }
                )
                
                // search name when at least 3 chars for profile propose
                if searchText.count > 2 {
                    filteredTokens.append(contentsOf: tokens
                        .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                    )
                }
                
                return filteredTokens.reduce(into: [ERC20Token]()) { result, token in
                    if !result.contains(token) {
                        result.append(token)
                    }
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
        let processor = DownsamplingImageProcessor(size: cell.logoImageView.frame.size)

        switch token.network {
        case .mainnet:
            guard let imageURL = URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/\(token.address)/logo.png") else {
                return
            }
            cell.logoImageView.kf.setImage(with: imageURL, placeholder: UIImage.placeholder(color: ._systemFill), options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(1)),
                .cacheOriginalImage
            ])
        default:
            guard let imageURL = URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/0x60B4E7dfc29dAC77a6d9f4b2D8b4568515E59c26/logo.png") else {
                return
            }
            cell.logoImageView.kf.setImage(with: imageURL, placeholder: UIImage.placeholder(color: ._systemFill), options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(1)),
                .cacheOriginalImage
            ])
        }
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
                    
                    var newTrie: Trie<Character> = Trie()
                    for token in tokens {
                        let symbol = token.symbol.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                        newTrie.inserted(ArraySlice(symbol.charactersArray), value: token.id)
                    }
                    self?.viewModel.trie.accept(newTrie)
                    
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
        let delegate = self.viewModel.customTokenViewControllerDelegate
        Coordinator.main.present(scene: .customToken(viewModel: viewModel, delegate: delegate), from: self, transition: .detail, completion: nil)
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
