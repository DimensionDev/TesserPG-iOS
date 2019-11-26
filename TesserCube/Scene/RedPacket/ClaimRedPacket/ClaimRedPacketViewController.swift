//
//  ClaimRedPacketViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-26.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import UIKit
import RxSwift
import RxCocoa
import RxSwiftUtilities
import RealmSwift
import Web3
import DMS_HDWallet_Cocoa
import DateToolsSwift

#if !TARGET_IS_EXTENSION
import SVProgressHUD
#endif

final class ClaimRedPacketViewModel: NSObject {
    
    let disposeBag = DisposeBag()
    let activityIndicator = ActivityIndicator()
    
    let selectWalletTableViewCell = SelectWalletTableViewCell()
    var walletProvider: RedPacketWalletProvider?
    
    // Input
    let redPacket: RedPacket
    
    // Output
    let isClaiming: Driver<Bool>
    let error = BehaviorRelay<Swift.Error?>(value: nil)
//
    let realm = RedPacketService.shared.realm!
    var redPacketNotificationToken: NotificationToken?
    
    init(redPacket: RedPacket) {
        self.redPacket = redPacket
        isClaiming = activityIndicator.asDriver()
        
        super.init()
        
        walletProvider = RedPacketWalletProvider(tableView: selectWalletTableViewCell.tableView, walletModels: WalletService.default.walletModels.value)
    }
    
    deinit {
        redPacketNotificationToken?.invalidate()
    }
    
}

extension ClaimRedPacketViewModel {
    
    func claimRedPacket() {
        guard let contractAddressHex = redPacket.contractAddress,
        let contractAddress = try? EthereumAddress(hex: contractAddressHex, eip55: false) else {
            // Error handle
            return
        }
        
        guard let walletModel = walletProvider?.selectWalletModel.value,
        let walletAddress = try? EthereumAddress(hex: walletModel.address, eip55: false),
        let hexPrivateKey = try? walletModel.hdWallet.privateKey().key.toHexString(),
        let privateKey = try? EthereumPrivateKey(hexPrivateKey: "0x" + hexPrivateKey) else {
            // Error handle
            return
        }
        
        let uuids = Array(redPacket.uuids)
        let checkAvailablity = WalletService.checkAvailablity(for: contractAddress).asObservable()
        let nonce = WalletService.getTransactionCount(address: walletAddress, block: .latest).asObservable()
    
        Observable.combineLatest(checkAvailablity, nonce)
            .flatMapLatest { checkAvailblity, nonce -> Observable<BigUInt> in
                let (balance, index) = checkAvailblity
                let uuid = uuids[Int(index)]
                return WalletService.claim(for: contractAddress, with: uuid, from: walletAddress, use: privateKey, nonce: nonce)
                    .asObservable()
                    .trackActivity(self.activityIndicator)
            }
            .observeOn(MainScheduler.asyncInstance)
            .debug()
            .subscribe(onNext: { [weak self] claimed in
                guard let `self` = self else { return }
                os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, String(claimed))
                // claimed
                // update red packet contractAddress & status
                try! self.realm.write {
                    self.redPacket.claimAmount = claimed
                    self.redPacket.status = .claimed
                }

            }, onError: { [weak self] error in
                os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                self?.error.accept(error)
            })
            .disposed(by: disposeBag)
    }
    
}

// MARK: - UITableViewDataSource
extension ClaimRedPacketViewModel: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RedPacketCardTableViewCell.self), for: indexPath) as! RedPacketCardTableViewCell
            CreatedRedPacketViewModel.configure(cell: cell, with: redPacket)
            return cell
            
        case 1:
            let cell = selectWalletTableViewCell
            cell.titleLabel.text = "Wallet"
            cell.detailLeadingLayoutConstraint.constant = 100
            return cell
            
        default:
            fatalError()
        }
    }
    
}

final class ClaimRedPacketViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    var viewModel: ClaimRedPacketViewModel!
    
    private lazy var closeBarButtonItem: UIBarButtonItem = {
        if #available(iOS 13.0, *) {
            return UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(ClaimRedPacketViewController.closeBarButtonItemPressed(_:)))
        } else {
            return UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(ClaimRedPacketViewController.closeBarButtonItemPressed(_:)))
        }
    }()
    
    private lazy var activityIndicatorBarButtonItem: UIBarButtonItem = {
        let activityIndicatorView: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            activityIndicatorView = UIActivityIndicatorView(style: .medium)
        } else {
            activityIndicatorView = UIActivityIndicatorView(style: .gray)
        }
        activityIndicatorView.startAnimating()
        let barButtonItem = UIBarButtonItem(customView: activityIndicatorView)
        return barButtonItem
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(RedPacketCardTableViewCell.self, forCellReuseIdentifier: String(describing: RedPacketCardTableViewCell.self))
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = ._systemGroupedBackground
        return tableView
    }()
    
    private lazy var bottomActionsView: UIStackView = {
        let stackView = UIStackView(frame: .zero)
        stackView.spacing = 12
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .fill
        return stackView
    }()
    
    lazy var openRedPacketButton: TCActionButton = {
        let button = TCActionButton()
        button.color = .systemBlue
        button.setTitle("Open Red Packet", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(ClaimRedPacketViewController.openRedPacketButtonPressed(_:)), for: .touchUpInside)
        return button
    }()
    
}

extension ClaimRedPacketViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Claim Red Packet"
        navigationItem.leftBarButtonItem = closeBarButtonItem
        
        // Layout tableView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        // Layout bottom actions view
        bottomActionsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomActionsView)
        NSLayoutConstraint.activate([
            bottomActionsView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            bottomActionsView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: bottomActionsView.bottomAnchor, constant: 15),
        ])
        
        // Setup tableView
        tableView.dataSource = viewModel
        
        // Setup bottomActionsView
        #if !TARGET_IS_EXTENSION
        reloadActionsView()
        #endif
        
        // Setup viewModel
        viewModel.isClaiming.drive(onNext: { [weak self] isClaiming in
            guard let `self` = self else { return }
                self.navigationItem.leftBarButtonItem = isClaiming ? nil : self.closeBarButtonItem
                self.navigationItem.rightBarButtonItem = isClaiming ? self.activityIndicatorBarButtonItem : nil
                self.openRedPacketButton.isEnabled = !isClaiming
            
                let title: String = {
                    if isClaiming {
                        return "Claiming"
                    } else {
                        return self.viewModel.redPacket.status == .claimed ? "Done" : "Open Red Packet"
                    }
                }()
            
                self.openRedPacketButton.setTitle(title, for: .normal)
            })
            .disposed(by: disposeBag)

        viewModel.redPacketNotificationToken = viewModel.redPacket.observe { [weak self] change in
            switch change {
            case .change(let changes):
                self?.tableView.reloadData()
                os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, changes.description)

            default:
                break
            }
        }
        
        viewModel.error.asDriver()
            .drive(onNext: { [weak self] error in
                guard let `self` = self, let error = error else { return }
                let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
    
}

extension ClaimRedPacketViewController {
    
    #if !TARGET_IS_EXTENSION
    private func reloadActionsView() {
        bottomActionsView.arrangedSubviews.forEach { subview in
            bottomActionsView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        bottomActionsView.addArrangedSubview(openRedPacketButton)
    }
    #endif
}

extension ClaimRedPacketViewController {
    
    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func openRedPacketButtonPressed(_ sender: UIButton) {
        if viewModel.redPacket.status == .claimed {
            dismiss(animated: true, completion: nil)
        } else {
            viewModel.claimRedPacket()
        }
    }
    
}

extension ClaimRedPacketViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
    
}
