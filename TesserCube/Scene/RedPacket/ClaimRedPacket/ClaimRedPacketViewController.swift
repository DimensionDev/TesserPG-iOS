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
        
    // Input
    let redPacket: RedPacket
    
    let walletModels = BehaviorRelay<[WalletModel]>(value: [])
    let selectWalletModel = BehaviorRelay<WalletModel?>(value: nil)
    
    // Output
    let isClaiming: Driver<Bool>
    let canDismiss = BehaviorRelay(value: true)
    let error = BehaviorRelay<Swift.Error?>(value: nil)

    var redPacketNotificationToken: NotificationToken?
    
    init(redPacket: RedPacket) {
        self.redPacket = redPacket
        isClaiming = activityIndicator.asDriver()
        
        super.init()
        
        // Update default select wallet model when wallet model pool change
        walletModels.asDriver()
            .map { $0.first }
            .drive(selectWalletModel)
            .disposed(by: disposeBag)
        
        isClaiming.asDriver()
            .map { !$0 }
            .drive(canDismiss)
            .disposed(by: disposeBag)
    }
    
    deinit {
        redPacketNotificationToken?.invalidate()
    }
    
}

extension ClaimRedPacketViewModel {
    
    func claimRedPacket() {
        guard let selectWalletModel = self.selectWalletModel.value,
        let walletAddress = try? EthereumAddress(hex: selectWalletModel.address, eip55: false) else {
            error.accept(RedPacketService.Error.internal("No valid wallet to claim"))
            return
        }
        
        let id = redPacket.id
        
        WalletService.getTransactionCount(address: walletAddress).asObservable()
            .withLatestFrom(isClaiming) { ($0, $1) }     // (nonce, isClaiming)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .filter { $0.1 == false }                               // not claiming
            .map { $0.0 }                                           // nonce
            .retry(3)
            .flatMap { nonce -> Observable<TransactionHash> in
                let redPacket: RedPacket
                do {
                    let realm = try RedPacketService.realm()
                    guard let _redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
                        return Observable.error(RedPacketService.Error.internal("cannot resolve red packet"))
                    }
                    redPacket = _redPacket
                } catch {
                    return Observable.error(error)
                }
                
                return RedPacketService.claim(for: redPacket, use: selectWalletModel, nonce: nonce)
                    .trackActivity(self.activityIndicator)
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] transactionHash in
                do {
                    // red packet claim transaction success
                    // set status to .claim_pending
                    let realm = try RedPacketService.realm()
                    guard let redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
                        return
                    }
                    try realm.write {
                        redPacket.claim_transaction_hash = transactionHash.hex()
                        redPacket.status = .claim_pending
                        redPacket.claim_address = selectWalletModel.address
                    }
                    
                    // let createdRedPacketViewController = CreatedRedPacketViewController()
                    // createdRedPacketViewController.viewModel = CreatedRedPacketViewModel(redPacket: redPacket)
                    // self?.navigationController?.pushViewController(createdRedPacketViewController, animated: true)
                    
                } catch {
                    self?.error.accept(error)
                }
            }, onError: { [weak self] error in
                self?.error.accept(error)
            })
            .disposed(by: disposeBag)
//        guard let contractAddressHex = redPacket.contractAddress,
//        let contractAddress = try? EthereumAddress(hex: contractAddressHex, eip55: false) else {
//            // Error handle
//            return
//        }
//        
//        guard let walletModel = walletProvider?.selectWalletModel.value,
//        let walletAddress = try? EthereumAddress(hex: walletModel.address, eip55: false),
//        let hexPrivateKey = try? walletModel.hdWallet.privateKey().key.toHexString(),
//        let privateKey = try? EthereumPrivateKey(hexPrivateKey: "0x" + hexPrivateKey) else {
//            // Error handle
//            return
//        }
//        
//        let uuids = Array(redPacket.uuids)
//        let checkAvailablity = WalletService.checkAvailablity(for: contractAddress).asObservable()
//        let nonce = WalletService.getTransactionCount(address: walletAddress, block: .latest).asObservable()
//    
//        Observable.combineLatest(checkAvailablity, nonce)
//            .flatMapLatest { checkAvailblity, nonce -> Observable<BigUInt> in
//                let (balance, _index) = checkAvailblity
//                let index = Int(_index)
//                guard index < uuids.count else {
//                    return Observable.error(WalletService.Error.checkAvailabilityEmpty)
//                }
//                let uuid = uuids[index]
//                return WalletService.claim(for: contractAddress, with: uuid, from: walletAddress, use: privateKey, nonce: nonce)
//                    .asObservable()
//                    .trackActivity(self.activityIndicator)
//            }
//            .observeOn(MainScheduler.asyncInstance)
//            .debug()
//            .subscribe(onNext: { [weak self] claimed in
//                guard let `self` = self else { return }
//                os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, String(claimed))
//                // claimed
//                // update red packet contractAddress & status
//                try! self.realm.write {
//                    self.redPacket.claimAmount = claimed
//                    self.redPacket.status = .claimed
//                }
//
//            }, onError: { [weak self] error in
//                os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//                guard let `self` = self else { return }
//                self.error.accept(error)
//                
//                if self.redPacket.status != .claimed {
//                    try! self.realm.write {
//                        self.redPacket.status = .empty
//                    }
//                }
//            })
//            .disposed(by: disposeBag)
    }
    
}

// MARK: - UITableViewDataSource
extension ClaimRedPacketViewModel: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // 0: Red packet section
        // 1: [In-App]   wallet select cell section
        // 2: [Keyboard] Open Red Packet button cell section
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            #if TARGET_IS_KEYBOARD
            return 0
            #else
            return 1
            #endif
        case 2:
            return 0
            // TODO:
            
            // #if TARGET_IS_KEYBOARD
            // return 1
            // #else
            // return 0
            // #endif
        default:
            fatalError()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        switch indexPath.section {
        case 0:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RedPacketCardTableViewCell.self), for: indexPath) as! RedPacketCardTableViewCell
            CreatedRedPacketViewModel.configure(cell: _cell, with: redPacket)
            
            cell = _cell
            
        case 1:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SelectWalletTableViewCell.self), for: indexPath) as! SelectWalletTableViewCell
            
            // Setup wallet view model
            walletModels.asDriver()
                .drive(_cell.viewModel.walletModels)
                .disposed(by: _cell.disposeBag)
            _cell.viewModel.selectWalletModel.asDriver()
                .drive(selectWalletModel)
                .disposed(by: _cell.disposeBag)
            
            // Setup separator line
            let topTag = 3868
            let bottomTag = 3869
            if let oldTopSeparatorLine = _cell.subviews.first(where: { $0.tag == topTag }) {
                oldTopSeparatorLine.removeFromSuperview()
            }
            if let oldBottomSeparatorLine = _cell.subviews.first(where: { $0.tag == bottomTag }) {
                oldBottomSeparatorLine.removeFromSuperview()
            }
            
            let topSeparatorLine: UIView = {
                let separatorLine = UIView(frame: CGRect(x: 0, y: 0, width: _cell.bounds.width, height: 0.5))
                separatorLine.tag = topTag
                separatorLine.backgroundColor = ._separator
                return separatorLine
            }()
            let bottomSeparatorLine: UIView = {
                let separatorLine = UIView(frame: CGRect(x: 0, y: 0, width: _cell.bounds.width, height: 0.5))
                separatorLine.tag = bottomTag
                separatorLine.backgroundColor = ._separator
                return separatorLine
            }()
            topSeparatorLine.translatesAutoresizingMaskIntoConstraints = false
            _cell.contentView.addSubview(topSeparatorLine)
            bottomSeparatorLine.translatesAutoresizingMaskIntoConstraints = false
            _cell.contentView.addSubview(bottomSeparatorLine)
            NSLayoutConstraint.activate([
                // not use contentView anchor here due to accessory view set padding for it
                topSeparatorLine.topAnchor.constraint(equalTo: _cell.topAnchor),
                topSeparatorLine.leadingAnchor.constraint(equalTo: _cell.leadingAnchor),
                topSeparatorLine.trailingAnchor.constraint(equalTo: _cell.trailingAnchor),
                topSeparatorLine.heightAnchor.constraint(equalToConstant: 0.5),
                bottomSeparatorLine.bottomAnchor.constraint(equalTo: _cell.bottomAnchor),
                bottomSeparatorLine.leadingAnchor.constraint(equalTo: _cell.leadingAnchor),
                bottomSeparatorLine.trailingAnchor.constraint(equalTo: _cell.trailingAnchor),
                bottomSeparatorLine.heightAnchor.constraint(equalToConstant: 0.5),
            ])
            
            cell = _cell
            
        default:
            fatalError()
        }
        
        return cell
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
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(RedPacketCardTableViewCell.self, forCellReuseIdentifier: String(describing: RedPacketCardTableViewCell.self))
        tableView.register(SelectWalletTableViewCell.self, forCellReuseIdentifier: String(describing: SelectWalletTableViewCell.self))
        tableView.separatorStyle = .none
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
        
        // Load bottom action in-app
        #if !TARGET_IS_KEYBOARD
        reloadActionsView()
        #endif
        
        // Setup viewModel
        WalletService.default.walletModels.asDriver()
            .drive(viewModel.walletModels)
            .disposed(by: disposeBag)
        
        viewModel.isClaiming.drive(onNext: { [weak self] isClaiming in
            guard let `self` = self else { return }
                self.navigationItem.leftBarButtonItem = isClaiming ? nil : self.closeBarButtonItem
                self.navigationItem.rightBarButtonItem = isClaiming ? self.activityIndicatorBarButtonItem : nil
                self.openRedPacketButton.isEnabled = !isClaiming
            
                let title: String = {
                    if isClaiming {
                        return "Claiming..."
                    } else {
                        return self.viewModel.redPacket.status == .claimed ? "Done" : "Open Red Packet"
                    }
                }()
            
                self.openRedPacketButton.setTitle(title, for: .normal)
            })
            .disposed(by: disposeBag)

        // update table view when red packet changes
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
        
        // Setup tableView
        tableView.dataSource = viewModel
        tableView.delegate = self
    }
    
}

extension ClaimRedPacketViewController {
    
    private func reloadActionsView() {
        bottomActionsView.arrangedSubviews.forEach { subview in
            bottomActionsView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        bottomActionsView.addArrangedSubview(openRedPacketButton)
    }

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

// MARK: - UIAdaptivePresentationControllerDelegate
extension ClaimRedPacketViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return viewModel.canDismiss.value
    }
    
}

// MARK: - UITableViewDelegate
extension ClaimRedPacketViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 1:     // select wallet cell section
            return 44
        default:
            return UITableView.automaticDimension
        }
    }
    
}
