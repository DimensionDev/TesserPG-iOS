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
import Kingfisher

final class CreatedRedPacketViewModel: NSObject {
    
    let disposeBag = DisposeBag()
    let activityIndicator = ActivityIndicator()
    
    // Input
    let redPacket: RedPacket
    let walletModel: WalletModel
    
    // Output
    let isFetching: Driver<Bool>
    let canShare: BehaviorRelay<Bool>
    let error = BehaviorRelay<Swift.Error?>(value: nil)
    
    var redPacketNotificationToken: NotificationToken?
    
    init(redPacket: RedPacket, walletModel: WalletModel) {
        self.redPacket = redPacket
        self.walletModel = walletModel
        
        isFetching = activityIndicator.asDriver()
        canShare = BehaviorRelay(value: RedPacketService.armoredEncPayload(for: redPacket) != nil)
        
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
    
    func fetchResult() {
        if redPacket.create_transaction_hash != nil {
            fetchCreateResult()
        } else {
            fetchApproveResult()
        }
    }
        
    func fetchCreateResult() {
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
    
    private func fetchApproveResult() {
        RedPacketService.shared.updateApproveResult(for: redPacket)
            .trackActivity(activityIndicator)
            .subscribe(onNext: { [weak self] approveEvent in
                // fetch create in realm listener in app: do nothing here
                
                #if TARGET_IS_KEYBOARD
                // and open app if in the keyboard
                guard let `self` = self else { return }
                // Delay for realm database write finish
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    UIApplication.sharedApplication().openCreatedRedPacketView(redpacket: self.redPacket)
                }
                #endif
                
            }, onError: { [weak self] error in
                self?.error.accept(error)
            })
            .disposed(by: disposeBag)
    }
    
    func createAfterApprove() {
        let walletValue = WalletValue(from: self.walletModel)
        // Init web3
        let network = redPacket.network
        let web3 = Web3Secret.web3(for: network)
        
        let walletAddress: EthereumAddress
        do {
            walletAddress = try EthereumAddress(hex: walletValue.address, eip55: false)
        } catch {
            self.error.accept(error)
            return
        }
        
        WalletService.getTransactionCount(address: walletAddress, web3: web3)
            .trackActivity(activityIndicator)
            .subscribeOn(ConcurrentMainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .retry(3)
            .flatMap { nonce -> Observable<TransactionHash> in
                return RedPacketService.shared.createAfterApprove(for: self.redPacket, use: walletValue, nonce: nonce)
                    .trackActivity(self.activityIndicator)
            }
            .subscribe(onNext: { transactionHash in
                // do nothing
            }, onError: { [weak self] error in
                self?.error.accept(error)
            })
            .disposed(by: disposeBag)
    }
    
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
        // Set name
        let name = "From: " + redPacket.sender_name + " (\(redPacket.network.rawValue))"
        cell.nameLabel.text = name
        
        // Set image
        switch redPacket.token_type {
        case .eth:
            cell.logoImageView.image = Asset.ethereumLogo.image
        case .erc20:
            let processor = DownsamplingImageProcessor(size: cell.logoImageView.frame.size)
            guard let token = redPacket.erc20_token,
            var imageURL = URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/\(token.address)/logo.png") else {
                cell.logoImageView.image = UIImage.placeholder(color: ._systemFill)
                break
            }
            
            if token.network == .rinkeby {
                imageURL = URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/0x60B4E7dfc29dAC77a6d9f4b2D8b4568515E59c26/logo.png")!
            }
            
            os_log("%{public}s[%{public}ld], %{public}s: load token image: %s", ((#file as NSString).lastPathComponent), #line, #function, imageURL.description)

            cell.logoImageView.kf
                .setImage(with: imageURL,
                          placeholder: UIImage.placeholder(color: ._systemFill),
                          options: [
                            .processor(processor),
                            .scaleFactor(UIScreen.main.scale),
                            .transition(.fade(1)),
                            .cacheOriginalImage
                    ]
                )
        }
        
        // Set message
        if !redPacket.send_message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            cell.messageLabel.text = redPacket.send_message
            cell.messageLabel.textColor = .white
        } else {
            cell.messageLabel.text = "Best Wishes!"
            cell.messageLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        }
        
        let helper = RedPacketHelper(for: redPacket)
        let totalAmountInDecimalString = helper.sendAmountInDecimalString ?? "-"
        let symbol = helper.symbol
        
        // Set detail
        let share = redPacket.uuids.count
        let unit = share > 1 ? "shares" : "share"
        cell.detailLabel.text = "\(totalAmountInDecimalString) \(symbol) / \(share) \(unit)"
        
        // Set create time
        if let blockCreationTime = redPacket.block_creation_time.value {
            let createDate = Date(timeIntervalSince1970: TimeInterval(blockCreationTime))
            if abs(createDate.timeIntervalSinceNow) > 1 * 24 * 60 * 60 {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                cell.leftFooterLabel.text = dateFormatter.string(from: createDate)
            } else {
                cell.leftFooterLabel.text = createDate.timeAgoSinceNow + " created"
            }
        } else {
            cell.leftFooterLabel.text = " "
        }
        
        // Set recived time
        if let receivedDate = redPacket.received_time {
            if abs(receivedDate.timeIntervalSinceNow) > 1 * 24 * 60 * 60 {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                cell.rightFooterLabel.text = dateFormatter.string(from: receivedDate)
            } else {
                cell.rightFooterLabel.text = receivedDate.timeAgoSinceNow + " received"
            }
        } else {
            cell.rightFooterLabel.text = " "
        }
        
        // Custom base on status
        switch redPacket.status {
        case .initial, .pending:
            cell.statusLabel.text = "Sending \(totalAmountInDecimalString) \(symbol)"
        case .fail:
            cell.statusLabel.text = "Failed to send"
        case .incoming:
            cell.statusLabel.text = ""
        case .normal:
            cell.statusLabel.text = ""
        case .claim_pending:
            cell.statusLabel.text = "Opening…"
        case .claimed:
            if let claimAmountInDecimalString = helper.claimAmountInDecimalString {
                cell.statusLabel.text = "Got \(claimAmountInDecimalString) \(symbol)"
            }
        case .empty:
            cell.statusLabel.text = "No more claimable"
            cell.detailLabel.text = "Too late to get any"
        case .expired:
            // if refunded
            if helper.refundAmountInBigUInt != BigUInt(0), let refundAmountInDecimalString = helper.refundAmountInDecimalString {
                cell.statusLabel.text = "Refunded \(refundAmountInDecimalString) \(symbol)"
                break
            }
            // if not refund and could be refund
            if helper.refundAmountInBigUInt == BigUInt(0), WalletService.default.walletModels.value.first(where: { $0.address == redPacket.sender_address }) != nil {
                cell.statusLabel.text = "Refundable"
                break
            }
            // if not refund and can not refund
            if helper.refundAmountInBigUInt == BigUInt(0) {
                cell.statusLabel.text = "Expired"
                cell.detailLabel.text = "Too late to get any"
                break
            }
            
        case .refund_pending:
            cell.statusLabel.text = "Refunding…"
        case .refunded:
            if let refundAmountInDecimalString = helper.refundAmountInDecimalString {
                cell.statusLabel.text = "Refund \(refundAmountInDecimalString)"
            } else {
                cell.statusLabel.text = "Refunded"
            }
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
        
        #if !TARGET_IS_KEYBOARD
        navigationItem.rightBarButtonItem = doneBarButtonItem
        #endif
        
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
        viewModel.redPacketNotificationToken = viewModel.redPacket.observe { [weak self] change in
            switch change {
            case .change(let changes):
                guard let `self` = self else { return }
                self.tableView.reloadData()
                self.viewModel.canShare.accept(RedPacketService.armoredEncPayload(for: self.viewModel.redPacket) != nil)
                os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, changes.description)
                
                // continue create if ERC20Token approve success
                let redPacket = self.viewModel.redPacket
                if redPacket.status == .pending && redPacket.create_transaction_hash == nil, redPacket.erc20_approve_value != nil {
                    
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
        
        // Teigger fetch create result action
        viewModel.fetchResult()
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
            label.text = "You may share this red packet after it is successfully\npublished on the Ethereum network."
            label.textColor = ._secondaryLabel
            label.font = FontFamily.SFProText.regular.font(size: 12)
            label.lineBreakMode = .byWordWrapping
            label.textAlignment = .center
            return label
        }()
        
        let buttonStackView = UIStackView()
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 15
        
        let doneButton: TCActionButton = {
            let button = TCActionButton()
            button.color = .white
            button.setTitle("Done", for: .normal)
            button.setTitleColor(.black, for: .normal)
            return button
        }()
        let shareButton: TCActionButton = {
            let button = TCActionButton()
            button.color = .systemBlue
            button.setTitle("Share", for: .normal)
            button.setTitleColor(.white, for: .normal)
            return button
        }()
        doneButton.addTarget(self, action: #selector(CreatedRedPacketViewController.doneButtonPressed(_:)), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(CreatedRedPacketViewController.shareButtonPressed(_:)), for: .touchUpInside)
        buttonStackView.addArrangedSubview(doneButton)
        buttonStackView.addArrangedSubview(shareButton)
        
        viewModel.canShare.asDriver()
            .drive(shareButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        bottomActionsView.addArrangedSubview(hintLabel)
        bottomActionsView.addArrangedSubview(buttonStackView)
    }
    
}
#endif

extension CreatedRedPacketViewController {
    
    @objc private func doneBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}

#if !TARGET_IS_EXTENSION
extension CreatedRedPacketViewController {

    @objc private func doneButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func shareButtonPressed(_ sender: UIButton) {
        guard let message = RedPacketService.armoredEncPayload(for: viewModel.redPacket) else {
            return
        }
        
        ShareUtil.share(message: message, from: self, over: sender)
    }

}
#endif
