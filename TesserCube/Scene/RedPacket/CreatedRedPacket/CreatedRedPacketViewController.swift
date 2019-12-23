//
//  CreatedRedPacketViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-23.
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

final class CreatedRedPacketViewModel: NSObject {
    
    let disposeBag = DisposeBag()
    let activityIndicator = ActivityIndicator()
    
    // Input
    let redPacket: RedPacket
    
    // Output
    let isFetching: Driver<Bool>
    let error = BehaviorRelay<Swift.Error?>(value: nil)
    // let message = BehaviorRelay<Message?>(value: nil)
    
    var redPacketNotificationToken: NotificationToken?
    
    init(redPacket: RedPacket) {
        self.redPacket = redPacket
        isFetching = activityIndicator.asDriver()
        
        super.init()
    
        isFetching
            .debug()
            .drive()
            .disposed(by: disposeBag)
    }
    
    deinit {
        redPacketNotificationToken?.invalidate()
    }
    
}

extension CreatedRedPacketViewModel {
    
    func fetchCreateResult() {
        // FIXME: it is duplicate with in-app pendingRedPackets create result updateer
        RedPacketService.shared.updateCreateResult(for: redPacket)
            .trackActivity(activityIndicator)
            .subscribe(onNext: { _ in
                // do nothing
                // use side effect to update red packet model
            }, onError: { [weak self] error in
                self?.error.accept(error)
            })
            .disposed(by: disposeBag)
    }
    
//    func deployRedPacketContract() {
//        Observable.just(redPacketProperty)
//            .withLatestFrom(isDeploying) { ($0, $1) }     // (redPacketProperty, isDeploying)
//            .filter { $0.1 == false }                     // not deploying
//            .map { $0.0 }                                 // redPacketProperty
//            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
//            .flatMapLatest { redPacketProperty -> Observable<RedPacketProperty> in
//                do {
//                    try WalletService.validate(redPacketProperty: redPacketProperty)
//                    return Observable.just(redPacketProperty)
//                } catch {
//                    return Observable.error(error)
//                }
//            }
//            .flatMapLatest { redPacketProperty -> Observable<EthereumData> in
//                os_log("%{public}s[%{public}ld], %{public}s: delopy RP contract for wallet %s", ((#file as NSString).lastPathComponent), #line, #function, redPacketProperty.walletModel!.address)
//                let walletAddress = try! EthereumAddress(hex: redPacketProperty.walletModel!.address, eip55: false)
//                return WalletService.getTransactionCount(address: walletAddress)
//                    .flatMap { nonce -> Single<EthereumData> in
//                        return WalletService.delopyRedPacket(for: redPacketProperty, nonce: nonce)
//                }
//                .do(onSuccess: { transactionHash in
//                    // Update red packet createContractTransactionHash
//                    DispatchQueue.main.async {
//                        try! self.realm.write {
//                            self.redPacket.createContractTransactionHash = transactionHash.hex()
//                        }
//                    }
//                })
//                .flatMap { transactionHash -> Single<EthereumData> in
//                    return WalletService.getContractAddress(transactionHash: transactionHash)
//                        .retryWhen({ error -> Observable<Int> in
//                            return error.enumerated().flatMap({ index, element -> Observable<Int> in
//                                os_log("%{public}s[%{public}ld], %{public}s: deploy contract fail retry %s times", ((#file as NSString).lastPathComponent), #line, #function, String(index + 1))
//                                // retry 6 times
//                                guard index < 6 else {
//                                    return Observable.error(element)
//                                }
//                                // retry every 10.0 sec
//                                return Observable.timer(10.0, scheduler: MainScheduler.instance)
//                            })
//                        })
//                }
//                .asObservable()
//                .trackActivity(self.activityIndicator)
//            }
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { [weak self] contractAddress in
//                guard let `self` = self else { return }
//
//                let contractAddressHex = contractAddress.hex()
//                let recipients = self.redPacketProperty.contactInfos.compactMap { $0.keys.first }
//
//                do {
//                    // Encrypt message without sign
//                    let messageBody = CreatedRedPacketViewModel.messageBody(for: self.redPacketProperty, contractAddress: contractAddressHex)
//                    let armored = try KeyFactory.encryptMessage(messageBody, signatureKey: nil, recipients: recipients)
//
//                    var message = Message(id: nil, senderKeyId: "", senderKeyUserId: "", composedAt: self.redPacket.createdAt as Date, interpretedAt: nil, isDraft: false, rawMessage: messageBody, encryptedMessage: armored)
//                    let messageInDB = try ProfileService.default.addMessage(&message, recipientKeys: recipients)
//
//                    self.message.accept(messageInDB)
//
//                    // update red packet contractAddress & status
//                    try! self.realm.write {
//                        self.redPacket.contractAddress = contractAddressHex
//                        self.redPacket.status = .normal
//                    }
//                } catch {
//                    self.error.accept(error)
//                }
//                os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, contractAddress.hex())
//            }, onError: { error in
//                self.error.accept(error)
//                try! self.realm.write {
//                    self.redPacket.status = .fail
//                }
//                os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//            })
//            .disposed(by: disposeBag)
//    }
    
}

extension CreatedRedPacketViewModel {
    
    /*
    static func messageBody(for redPacketProperty: RedPacketProperty, contractAddress: String) -> String {
        let senderPublicKeyFingerprint = redPacketProperty.sender?.fingerprint ?? ""
        let senderUserID = redPacketProperty.sender?.userID ?? ""
        let uuids = redPacketProperty.uuids.joined(separator: "\n")
        return """
        -----BEGIN RED PACKET-----
        \(senderPublicKeyFingerprint):\(senderUserID)
        \(contractAddress)
        \(uuids)
        -----END RED PACKET-----
        """
    }
     */
    
}

// MARK: - UITableViewDataSource
extension CreatedRedPacketViewModel: UITableViewDataSource {
    
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

extension CreatedRedPacketViewModel {
    
    static func configure(cell: RedPacketCardTableViewCell, with redPacket: RedPacket) {
        cell.nameLabel.text = redPacket.sender_name
        cell.emailLabel.text = ""       // no more email

        let formatter = NumberFormatter.decimalFormatterForETH
        let totalAmountInDecimal = (Decimal(string: String(redPacket.send_total)) ?? Decimal(0)) / HDWallet.CoinType.ether.exponent
        let totalAmountInDecimalString = formatter.string(from: totalAmountInDecimal as NSNumber) ?? "-"
        
        switch redPacket.status {
        case .initial, .pending:
            cell.redPacketStatusLabel.text = "Outgoing Red Packet"
            cell.indicatorLabel.text = "Publishing…"
        case .fail:
            cell.redPacketStatusLabel.text = "Failed to send"
            cell.indicatorLabel.text = ""
        case .incoming:
            cell.redPacketStatusLabel.text = "Incoming Red Packet"
            cell.redPacketDetailLabel.text = "Trying to claim…"
            cell.indicatorLabel.text = ""
        case .normal:
            cell.redPacketStatusLabel.text = "Sent \(totalAmountInDecimalString) ETH"
            cell.indicatorLabel.text = "Ready for collection"
        case .claim_pending:
            cell.redPacketStatusLabel.text = "Claiming…"
            cell.indicatorLabel.text = ""
        case .claimed:
            let amountInDecimal = (Decimal(string: String(redPacket.claim_amount)) ?? Decimal(0)) / HDWallet.CoinType.ether.exponent
            let amountInDecimalString = formatter.string(from: amountInDecimal as NSNumber) ?? "-"
            cell.redPacketStatusLabel.text = "Got \(amountInDecimalString) ETH"
            cell.indicatorLabel.text = ""
        case .empty:
            cell.redPacketStatusLabel.text = "Too late to get any"
            cell.indicatorLabel.text = ""
        case .expired:
            cell.redPacketStatusLabel.text = "Too late to get any"
            cell.indicatorLabel.text = ""
        case .refund_pending:
            cell.redPacketStatusLabel.text = "Refunding…"
            cell.indicatorLabel.text = ""
        case .refunded:
            let amountInDecimal = (Decimal(string: String(redPacket.refund_amount)) ?? Decimal(0)) / HDWallet.CoinType.ether.exponent
            let amountInDecimalString = formatter.string(from: amountInDecimal as NSNumber) ?? "-"
            cell.redPacketStatusLabel.text = "Refund \(amountInDecimalString) ETH"
            cell.indicatorLabel.text = ""
        }

        let share = redPacket.uuids.count
        let unit = share > 1 ? "shares" : "share"
        cell.redPacketDetailLabel.text = "\(totalAmountInDecimalString) ETH in total / \(share) \(unit)"

        if let blockCreationTime = redPacket.block_creation_time.value {
            let createDate = Date(timeIntervalSince1970: TimeInterval(blockCreationTime))
            cell.createdDateLabel.text = createDate.timeAgoSinceNow + " created"
            
        } else {
            cell.createdDateLabel.text = " "
        }
    }
    
}

final class CreatedRedPacketViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    var viewModel: CreatedRedPacketViewModel!
    
    private lazy var doneBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(CreatedRedPacketViewController.doneBarButtonItemPressed(_:)))
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
    
}

extension CreatedRedPacketViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Red Packet Created"
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = doneBarButtonItem
        
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
        // reloadActionsView()
        #endif
        
        // Setup viewModel
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
        
        // Teigger fetch create result action
         viewModel.fetchCreateResult()
    }
    
}

#if !TARGET_IS_EXTENSION
extension CreatedRedPacketViewController {
    
    private func reloadActionsView() {
        bottomActionsView.arrangedSubviews.forEach { subview in
            bottomActionsView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        let hintLabel: UILabel = {
            let label = UILabel()
            label.numberOfLines = 0
            label.text = "Recipients may interpret the hint with Tesercube to open the Red Packet."
            label.font = FontFamily.SFProDisplay.regular.font(size: 20)
            label.lineBreakMode = .byWordWrapping
            label.textAlignment = .center
            return label
        }()
        let shareRedPacketButton: TCActionButton = {
            let button = TCActionButton()
            button.color = .systemBlue
            button.setTitle("Share Red Packet", for: .normal)
            button.setTitleColor(.white, for: .normal)
            return button
        }()
        
        bottomActionsView.addArrangedSubview(hintLabel)
        bottomActionsView.addArrangedSubview(shareRedPacketButton)
    }
}
#endif

extension CreatedRedPacketViewController {
    
    @objc private func doneBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}
