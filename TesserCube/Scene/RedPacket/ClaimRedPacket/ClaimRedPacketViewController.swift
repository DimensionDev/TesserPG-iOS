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
    let busyActivityIndicator = ActivityIndicator()
    let claimActivityIndicator = ActivityIndicator()
    let updateClaimResultActivityIndicator = ActivityIndicator()
        
    // Input
    let redPacket: RedPacket

    let walletModels = BehaviorRelay<[WalletModel]>(value: [])
    let selectWalletModel = BehaviorRelay<WalletModel?>(value: nil)
    
    let isClaimPending: BehaviorRelay<Bool>
    
    // Output
    let isClaiming: Driver<Bool>
    let isBusy = BehaviorRelay(value: false)
    let canDismiss = BehaviorRelay(value: true)
    let error = BehaviorRelay<Swift.Error?>(value: nil)
    var redPacketNotificationToken: NotificationToken?
    
    init(redPacket: RedPacket) {
        self.redPacket = redPacket
        isClaimPending = BehaviorRelay(value: redPacket.status == .claim_pending)
        isClaiming = claimActivityIndicator.asDriver()
                
        super.init()
        
        busyActivityIndicator.asDriver()
            .drive(isBusy)
            .disposed(by: disposeBag)
        
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
        os_log("%{public}s[%{public}ld], %{public}s: deinit", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ClaimRedPacketViewModel {
    
    func claimRedPacket() {
        // 1. claim                  // busy & claiming
        // 2. get claim result       // busy & claimPending
        
        guard let selectWalletModel = self.selectWalletModel.value,
        let walletAddress = try? EthereumAddress(hex: selectWalletModel.address, eip55: false) else {
            error.accept(RedPacketService.Error.internal("No valid wallet to claim"))
            return
        }
        
        // Break if busy
        guard !isBusy.value else {
            return
        }
        
        let id = redPacket.id
        
        // Init web3
        let network = redPacket.network
        let web3 = Web3Secret.web3(for: network)
        
        WalletService.getTransactionCount(address: walletAddress, web3: web3).asObservable()
            .trackActivity(busyActivityIndicator)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
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
                
                return RedPacketService.shared.claim(for: redPacket, use: selectWalletModel, nonce: nonce)
                    .trackActivity(self.busyActivityIndicator)
                    .trackActivity(self.claimActivityIndicator)
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] transactionHash in     // now_claim_pending
                // do nothing
                // force realm operation listener notified then to fetch claim result to fix claimTransactionHash not found race issue
            }, onError: { [weak self] error in
                self?.error.accept(error)
            })
            .disposed(by: disposeBag)
    }
    
    func fetchClaimResult() {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

        RedPacketService.shared.updateClaimResult(for: redPacket)
            .trackActivity(busyActivityIndicator)
            .trackActivity(updateClaimResultActivityIndicator)
            .subscribe(onNext: { _ in
                // do nothing
                // use side effect to update red packet model
            }, onError: { [weak self] error in
                self?.error.accept(error)
            })
            .disposed(by: disposeBag)
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
            
            walletModels.bind(to: _cell.walletPickerView.rx.items) { index, item, view in
                let label = (view as? UILabel) ?? UILabel()
                label.textAlignment = .center
                label.adjustsFontSizeToFitWidth = true
                label.text = "Wallet \(item.address.prefix(6))"
                return label
            }
            .disposed(by: _cell.disposeBag)
            
            selectWalletModel.asDriver()
                .map { walletModel in
                    guard let walletModel = walletModel else {
                        return L10n.Common.Label.nameNone
                    }
                    
                    return "Wallet \(walletModel.address.prefix(6))"
                }
                .drive(_cell.walletTextField.rx.text)
                .disposed(by: _cell.disposeBag)
        
            #if !TARGET_IS_KEYBOARD
            _cell.walletPickerView.rx.modelSelected(WalletModel.self)
                .asDriver()
                .map { $0.first }
                .drive(selectWalletModel)
                .disposed(by: disposeBag)
            #endif
            
            // Setup separator line
            UITableView.setupTopSectionSeparatorLine(for: _cell)
            UITableView.setupBottomSectionSeparatorLine(for: _cell)
            
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
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s: deinit", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ClaimRedPacketViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Claim Red Packet"
        navigationItem.leftBarButtonItem = closeBarButtonItem
        navigationItem.hidesBackButton = true
        
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
        
        viewModel.isBusy.asDriver()
            .drive(onNext: { [weak self] isBusy in
                guard let `self` = self else { return }
                self.navigationItem.rightBarButtonItem = isBusy ? self.activityIndicatorBarButtonItem : nil
                self.openRedPacketButton.isEnabled = !isBusy
            
                let title: String = {
                    if isBusy {
                        return "Claiming..."
                    } else {
                        return self.viewModel.redPacket.status == .claimed ? "Done" : "Open Red Packet"
                    }
                }()
                
                self.openRedPacketButton.setTitle(title, for: .normal)
            })
            .disposed(by: disposeBag)
        
        viewModel.isClaiming.drive(onNext: { [weak self] isClaiming in
            guard let `self` = self else { return }
                self.closeBarButtonItem.isEnabled = !isClaiming
                self.tableView.isUserInteractionEnabled = !isClaiming
            })
            .disposed(by: disposeBag)

        viewModel.redPacketNotificationToken = viewModel.redPacket.observe { [weak self] change in
            guard let `self` = self else { return }
            switch change {
            case .change(let changes):
                os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, changes.description)

                // set status
                self.viewModel.isClaimPending.accept(self.viewModel.redPacket.status == .claim_pending)

                // update table view when red packet changes
                self.tableView.reloadData()
                    
                // fetch claim result
                if self.viewModel.redPacket.status == .claim_pending {
                    self.viewModel.fetchClaimResult()
                }

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
        
        // Trigger claim result updater if pending
        if viewModel.redPacket.status == .claim_pending {
            viewModel.fetchClaimResult()
        }
        
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
