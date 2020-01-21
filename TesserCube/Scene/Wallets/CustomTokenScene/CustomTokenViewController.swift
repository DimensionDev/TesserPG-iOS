//
//  CustomTokenViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-15.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

typealias TokenInfo = (name: String, symbol: String, decimals: Int)

final class CustomTokenViewModel: NSObject {
    
    let disposeBag = DisposeBag()
    
    let sections: [[TableViewCellType]] = [
        [
            .tokenAddressInput
        ],
        [
            .tokenName,
            .tokenSymbol,
            .tokenDecimals,
        ],
    ]
    
    // Input
    let inputAddress = BehaviorRelay(value: "")
    
    // Output
    let name = BehaviorRelay<String?>(value: nil)
    let symbol = BehaviorRelay<String?>(value: nil)
    let decimals = BehaviorRelay<Int?>(value: nil)
    
    let token = BehaviorRelay<ERC20Token?>(value: nil)
    
    override init() {
        super.init()
        
        inputAddress.asObservable()
            .debug()
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribeOn(ConcurrentMainScheduler.instance)
            .flatMapLatest { input -> Observable<TokenInfo?> in
                let contractAddress = input.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !contractAddress.isEmpty else {
                    return Observable.just(nil)
                }
                
                // Init web3
                // use current network for custom token
                let network = EthereumPreference.ethereumNetwork
                let web3 = Web3Secret.web3(for: network)
                
                let name = RedPacketService.ERC20.name(for: contractAddress, web3: web3).asObservable()
                let symbol = RedPacketService.ERC20.symbol(for: contractAddress, web3: web3).asObservable()
                let decimals = RedPacketService.ERC20.decimals(for: contractAddress, web3: web3).asObservable()
                return Observable.combineLatest(name, symbol, decimals)
                    .retry(3)
                    .map { name, symbol, decimals in
                        return TokenInfo(name: name, symbol: symbol, decimals: decimals)
                    }
                    .catchErrorJustReturn(nil)
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] tokenInfo in
                guard let `self` = self else { return }
                
                self.name.accept(tokenInfo?.name)
                self.symbol.accept(tokenInfo?.symbol)
                self.decimals.accept(tokenInfo?.decimals)
                
                guard let name = tokenInfo?.name, let symbol = tokenInfo?.symbol, let decimals = tokenInfo?.decimals else {
                    self.token.accept(nil)
                    return
                }
                let token = ERC20Token()
                token.id = self.inputAddress.value
                token.address = self.inputAddress.value
                token.name = name
                token.symbol = symbol
                token.decimals = decimals
                #if MAINNET
                token.network = .mainnet
                #else
                token.network = .rinkeby
                #endif
                token.is_user_defind = true
                
                self.token.accept(token)
                
            }, onError: { [weak self] error in
                self?.name.accept(nil)
                self?.symbol.accept(nil)
                self?.decimals.accept(nil)
                self?.token.accept(nil)
            })
            .disposed(by: disposeBag)
    }
    
}

extension CustomTokenViewModel {
    
    enum TableViewCellType: CaseIterable {
        case tokenAddressInput
        case tokenName
        case tokenSymbol
        case tokenDecimals
    }
    
}

extension CustomTokenViewModel: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        switch sections[indexPath.section][indexPath.row] {
        case .tokenAddressInput:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TokenAddressInputTableViewCell.self), for: indexPath) as! TokenAddressInputTableViewCell
            _cell.addressTextField.rx.text.orEmpty.asDriver()
                .drive(inputAddress)
                .disposed(by: _cell.disposeBag)
            
            cell = _cell

        case .tokenName:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TokenInfoTableViewCell.self), for: indexPath) as! TokenInfoTableViewCell
            _cell.titleLabel.text = "Name"
            name.asDriver()
                .drive(_cell.infoTextField.rx.text)
                .disposed(by: _cell.disposeBag)
            
            cell = _cell

        case .tokenSymbol:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TokenInfoTableViewCell.self), for: indexPath) as! TokenInfoTableViewCell
            _cell.titleLabel.text = "Symbol"
            symbol.asDriver()
                .drive(_cell.infoTextField.rx.text)
                .disposed(by: _cell.disposeBag)
            
            cell = _cell
            
        case .tokenDecimals:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TokenInfoTableViewCell.self), for: indexPath) as! TokenInfoTableViewCell
            _cell.titleLabel.text = "Decimals"
            decimals.asDriver()
                .map { $0.flatMap { String($0) } }
                .drive(_cell.infoTextField.rx.text)
                .disposed(by: _cell.disposeBag)
            
            cell = _cell
        }
        
        return cell
    }

}

protocol CustomTokenViewControllerDelegate: class {
    func customTokenViewController(_ controller: CustomTokenViewController, didFinishWithToken token: ERC20Token)
}

final class CustomTokenViewController: TCBaseViewController {
    
    var viewModel: CustomTokenViewModel!
    weak var delegate: CustomTokenViewControllerDelegate?
    
    private lazy var finishBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(title: "Finish", style: .done, target: self, action: #selector(CustomTokenViewController.finishBarButtonItemPressed(_:)))
        return barButtonItem
    }()
    
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(TokenAddressInputTableViewCell.self, forCellReuseIdentifier: String(describing: TokenAddressInputTableViewCell.self))
        tableView.register(TokenInfoTableViewCell.self, forCellReuseIdentifier: String(describing: TokenInfoTableViewCell.self))
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: 40))
        return tableView
    }()
    
    let tokenAddressInputSectionHeaderView: UIView = {
        let headerView = UIView()
        headerView.preservesSuperviewLayoutMargins = true

        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 13)
        label.textColor = ._secondaryLabel
        label.text = "Token Contract Address"
        
        label.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: headerView.topAnchor),
            label.leadingAnchor.constraint(equalTo: headerView.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: headerView.layoutMarginsGuide.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
        ])
        
        return headerView
    }()
    
    override func configUI() {
        super.configUI()
        
        navigationItem.rightBarButtonItem = finishBarButtonItem
        
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
    
}

extension CustomTokenViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Set forcus when appear
        if let tokenAddressInputTableViewCell = tableView.cellForRow(at: IndexPath(item: 0, section: 0)) as? TokenAddressInputTableViewCell {
            tokenAddressInputTableViewCell.addressTextField.becomeFirstResponder()
        }
    }
    
}

extension CustomTokenViewController {
    
    @objc func finishBarButtonItemPressed(_ sender: UIBarButtonItem) {
        guard let token = viewModel.token.value else {
            let alertController = UIAlertController(title: "Error", message: "cannot find valid token info on this address", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
            
            return
        }
        
        delegate?.customTokenViewController(self, didFinishWithToken: token)
    }
    
}

// MAKR: - UITableViewDelegate
extension CustomTokenViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let firstTableViewCellType = viewModel.sections[section].first else {
            return UIView()
        }
        
        switch firstTableViewCellType {
        case .tokenAddressInput:
            return tokenAddressInputSectionHeaderView
        default:
            return UIView()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let firstTableViewCellType = viewModel.sections[section].first else {
            return 10
        }
        
        switch firstTableViewCellType {
        case .tokenAddressInput:
            return UITableView.automaticDimension
        default:
            return 10
        }
    }
    
}
