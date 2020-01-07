//
//  RefundRedPacketViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-30.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import UIKit
import RealmSwift
import RxSwift
import RxCocoa
import RxRealm
import RxSwiftUtilities
import Web3

final class RefundRedPacketViewModel: NSObject {
    
    let disposeBag = DisposeBag()
    let busyActivityIndicator = ActivityIndicator()
    let refundActivityIndicator = ActivityIndicator()
    
    // Input
    let redPacket: RedPacket
    let isRefundPending: BehaviorRelay<Bool>
    
    // Output
    let isRefunding: Driver<Bool>
    let isBusy = BehaviorRelay(value: false)
    var redPacketNotificationToken: NotificationToken?
    let error = BehaviorRelay<Swift.Error?>(value: nil)
    
    init(redPacket: RedPacket) {
        self.redPacket = redPacket
        isRefundPending = BehaviorRelay(value: redPacket.status == .refund_pending)
        isRefunding = refundActivityIndicator.asDriver()
        super.init()
        
        busyActivityIndicator.asDriver()
            .drive(isBusy)
            .disposed(by: disposeBag)
         
        isBusy.asDriver()
            .drive(onNext: { isBusy in
                os_log("%{public}s[%{public}ld], %{public}s: isBusy %s", ((#file as NSString).lastPathComponent), #line, #function, String(isBusy))
            })
            .disposed(by: disposeBag)
        
        isRefunding.asDriver()
            .drive(onNext: { isRefunding in
                os_log("%{public}s[%{public}ld], %{public}s: isRefunding %s", ((#file as NSString).lastPathComponent), #line, #function, String(isRefunding))
            })
            .disposed(by: disposeBag)
    }
    
    deinit {
        redPacketNotificationToken?.invalidate()
        os_log("%{public}s[%{public}ld], %{public}s: deinit", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension RefundRedPacketViewModel {
    
    func refundRedpacket() {
        // 1. Get nonce                         // busy
        // 2. Send refund transaction           // busy & refunding
        // 3. Fetch refund result               // busy & refundPending
        
        // Find sender wallet for refund
        let walletModelForRefund = WalletService.default.walletModels.value.first(where: { walletModel -> Bool in
            return walletModel.address == redPacket.sender_address
        })
        
        guard let walletModel = walletModelForRefund else {
            error.accept(RedPacketService.Error.internal("cannot find wallet to refund this red packet"))
            return
        }
        guard let walletAddress = try? EthereumAddress(hex: walletModel.address, eip55: false) else {
            error.accept(RedPacketService.Error.internal("No valid wallet to refund"))
            return
        }
        
        // Break if busy
        guard !isBusy.value else {
            return
        }

        let id = redPacket.id

        WalletService.getTransactionCount(address: walletAddress).asObservable()
            .trackActivity(busyActivityIndicator)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .retry(3)
            .flatMapLatest { nonce -> Observable<TransactionHash> in
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
                
                return RedPacketService.shared.refund(for: redPacket, use: walletModel, nonce: nonce)
                    .trackActivity(self.refundActivityIndicator)
                    .trackActivity(self.busyActivityIndicator)
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] transactionHash in
                // do nothing
                // force realm operation listener notified then to fetch claim result to fix claimTransactionHash not found race issue
            }, onError: { [weak self] error in
                self?.error.accept(error)
            })
            .disposed(by: disposeBag)
        
    }
    
    func fetchRefundResult() {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

        RedPacketService.shared.updateRefundResult(for: redPacket)
            .trackActivity(busyActivityIndicator)
            .subscribe(onNext: { _ in
                // do nothing
            }, onError: { [weak self] error in
                self?.error.accept(error)
            })
            .disposed(by: disposeBag)
    }
    
}

// MARK: - UITableViewDataSource
extension RefundRedPacketViewModel: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RedPacketCardTableViewCell.self), for: indexPath) as! RedPacketCardTableViewCell
        CreatedRedPacketViewModel.configure(cell: cell, with: redPacket)
        return cell
    }
    
}

final class RefundRedPacketViewController: TCBaseViewController {
    
    let disposeBag = DisposeBag()
    
    var viewModel: RefundRedPacketViewModel!
    
    private lazy var closeBarButtonItem: UIBarButtonItem = {
        if #available(iOS 13.0, *) {
            return UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(RefundRedPacketViewController.closeBarButtonItemPressed(_:)))
        } else {
            return UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(RefundRedPacketViewController.closeBarButtonItemPressed(_:)))
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
    
    lazy var refundRedPacketButton: TCActionButton = {
        let button = TCActionButton()
        button.color = .systemBlue
        button.setTitle("Refund Red Packet", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(RefundRedPacketViewController.refundRedPacketButtonPressed(_:)), for: .touchUpInside)
        return button
    }()

    override func configUI() {
        super.configUI()
        
        title = "Refund Red Packet"
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
        
        // Load bottom action view
        reloadActionsView()
        
        // Setup error handler
        viewModel.error.asDriver()
            .drive(onNext: { [weak self] error in
                guard let `self` = self, let error = error else { return }
                let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        // Setup table view
        tableView.delegate = self
        tableView.dataSource = viewModel
        
        viewModel.redPacketNotificationToken = viewModel.redPacket.observe { [weak self] change in
            guard let `self` = self else { return }
            switch change {
            case .change(let changes):
                os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, changes.description)

                // update table view when red packet changes
                self.tableView.reloadData()
                    
                // fetch refund result
                if self.viewModel.redPacket.status == .refund_pending {
                    self.viewModel.fetchRefundResult()
                }
                
            default:
                break
            }
        }
        
        viewModel.isBusy.asDriver()
            .drive(onNext: { [weak self] isBusy in
                guard let `self` = self else { return }
                self.navigationItem.rightBarButtonItem = isBusy ? self.activityIndicatorBarButtonItem : nil
                self.refundRedPacketButton.isEnabled = !isBusy
                
                let title: String = {
                    if isBusy {
                        return "Refunding"
                    } else {
                        return self.viewModel.redPacket.status == .refunded ? "Done" : "Refund Red Packet"
                    }
                }()
                self.refundRedPacketButton.setTitle(title, for: .normal)
            })
            .disposed(by: disposeBag)
    }
    
}

extension RefundRedPacketViewController {
    
    private func reloadActionsView() {
        bottomActionsView.arrangedSubviews.forEach { subview in
            bottomActionsView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        bottomActionsView.addArrangedSubview(refundRedPacketButton)
    }
    
}

extension RefundRedPacketViewController {
    
    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func refundRedPacketButtonPressed(_ sender: UIButton) {
        if viewModel.redPacket.status == .refunded {
            dismiss(animated: true, completion: nil)
        } else {
            viewModel.refundRedpacket()
        }
    }
    
}

// MARK: - UITableViewDelegate
extension RefundRedPacketViewController: UITableViewDelegate {

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
    
}
