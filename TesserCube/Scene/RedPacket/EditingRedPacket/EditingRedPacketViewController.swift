//
//  EditingRedPacketViewController.swift
//  TesserCube
//
//  Created by jk234ert on 11/6/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import UIKit
import RxSwift
import RxCocoa
import RxSwiftUtilities
import BigInt
import DMS_HDWallet_Cocoa
import Web3

final class EditingRedPacketViewModel: NSObject {
    
    let disposeBag = DisposeBag()
    let createActivityIndicator = ActivityIndicator()
    
    // Input
    let redPacketSplitType = BehaviorRelay(value: SplitType.average)
    
    let walletModels = BehaviorRelay<[WalletModel]>(value: [])
    let selectWalletModel = BehaviorRelay<WalletModel?>(value: nil)
    
    let amount = BehaviorRelay(value: Decimal(0))       // user input value. default 0
    let share = BehaviorRelay(value: 1)
    
    let name = BehaviorRelay(value: "")
    let message = BehaviorRelay(value: "")
    
    // Output
    let isCreating: Driver<Bool>
    let canDismiss = BehaviorRelay(value: true)
    let amountInputCoinCurrencyUnitLabelText: Driver<String>
    let minimalAmount = BehaviorRelay(value: RedPacketService.redPacketMinAmount)
    let total = BehaviorRelay(value: Decimal(0))     // should not 0 after user input amount
    let sendRedPacketButtonText: Driver<String>

    enum TableViewCellType {
        case wallet                 // select a wallet to send red packet
        case amount                 // input the amount for send
        case share                  // input the count for shares
        case name                   // input the sender name
        case message                // input the comment message
    }
    
    let sections: [[TableViewCellType]] = [
        [
            .wallet,
        ],
        [
            .amount,
            .share,
        ],
        [
            .name,
            .message,
        ],
    ]
    
    override init() {
        isCreating = createActivityIndicator.asDriver()
        amountInputCoinCurrencyUnitLabelText = redPacketSplitType.asDriver()
            .map { type in type == .average ? "ETH per share" : "ETH" }
        sendRedPacketButtonText = total.asDriver()
            .map { total in
                guard total > 0, let totalInETH = NumberFormatter.decimalFormatterForETH.string(from: total as NSNumber) else {
                    return "Send"
                }
                
                return "Send \(totalInETH) ETH"
            }
        super.init()
        
        // Update default select wallet model when wallet model pool change
        walletModels.asDriver()
            .map { $0.first }
            .drive(selectWalletModel)
            .disposed(by: disposeBag)
        
        Driver.combineLatest(share.asDriver(), redPacketSplitType.asDriver()) { share, splitType -> Decimal in
                switch splitType {
                case .average:
                    return RedPacketService.redPacketMinAmount
                case .random:
                    return Decimal(share) * RedPacketService.redPacketMinAmount
                }
            }
            .drive(minimalAmount)
            .disposed(by: disposeBag)
        
        Driver.combineLatest(redPacketSplitType.asDriver(), amount.asDriver(), share.asDriver()) { splitType, amount, share -> Decimal in
                switch splitType {
                case .random:
                    return amount
                case .average:
                    return amount * Decimal(share)
                }
            }
            .drive(total)
            .disposed(by: disposeBag)
        
        isCreating.asDriver()
            .map { !$0 }
            .drive(canDismiss)
            .disposed(by: disposeBag)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension EditingRedPacketViewModel {
    
    enum SplitType: Int, CaseIterable {
        case average
        case random
        
        var title: String {
            switch self {
            case .average:
                return "Average"
            case .random:
                return "Random"
            }
        }
    }
    
}

// MARK: - UITableViewDataSource
extension EditingRedPacketViewModel: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        switch sections[indexPath.section][indexPath.row] {
        case .wallet:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SelectWalletTableViewCell.self), for: indexPath) as! SelectWalletTableViewCell
            walletModels.asDriver()
                .drive(_cell.viewModel.walletModels)
                .disposed(by: _cell.disposeBag)
            _cell.viewModel.selectWalletModel.asDriver()
                .drive(selectWalletModel)
                .disposed(by: _cell.disposeBag)
            cell = _cell
        
        case .amount:
            #if TARGET_IS_KEYBOARD
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: KeyboardInputRedPacketAmoutCell.self), for: indexPath) as! KeyboardInputRedPacketAmoutCell
            #else
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: InputRedPacketAmoutTableViewCell.self), for: indexPath) as! InputRedPacketAmoutTableViewCell
            #endif
            
            
            // Bind coin currency unit label text to label
            amountInputCoinCurrencyUnitLabelText.asDriver()
                .drive(_cell.coinCurrencyUnitLabel.rx.text)
                .disposed(by: _cell.disposeBag)
            
            _cell.amount.asDriver()
                .drive(amount)
                .disposed(by: _cell.disposeBag)
            
            minimalAmount.asDriver()
                .drive(_cell.minimalAmount)
                .disposed(by: _cell.disposeBag)
            
            cell = _cell
        
        case .share:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: InputRedPacketShareTableViewCell.self), for: indexPath) as! InputRedPacketShareTableViewCell
            
            _cell.share.asDriver()
                .drive(share)
                .disposed(by: disposeBag)
            
            cell = _cell
            
        case .name:
            #if TARGET_IS_KEYBOARD
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: KeyboardInputRedPacketSenderCell.self), for: indexPath) as! KeyboardInputRedPacketSenderCell
            _cell.nameTextField.inputTextField.rx.text.orEmpty.asDriver()
                .drive(name)
                .disposed(by: _cell.disposeBag)
            #else
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: InputRedPacketSenderTableViewCell.self), for: indexPath) as! InputRedPacketSenderTableViewCell
            _cell.nameTextField.rx.text.orEmpty.asDriver()
                .drive(name)
                .disposed(by: _cell.disposeBag)
            #endif
            
            cell = _cell
            
        case .message:
            #if TARGET_IS_KEYBOARD
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: KeyboardInputRedPacketMessageCell.self), for: indexPath) as! KeyboardInputRedPacketMessageCell
            _cell.messageTextField.inputTextField.rx.text.orEmpty.asDriver()
                .drive(message)
                .disposed(by: _cell.disposeBag)
            #else
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: InputRedPacketMessageTableViewCell.self), for: indexPath) as! InputRedPacketMessageTableViewCell
            _cell.messageTextField.rx.text.orEmpty.asDriver()
                .drive(message)
                .disposed(by: _cell.disposeBag)
            #endif
            
            cell = _cell
        }
        
        return cell
    }
    
}

class EditingRedPacketViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    private(set) lazy var closeBarButtonItem: UIBarButtonItem = {
        // Use iOS 13 style .close button if possiable
        if #available(iOS 13.0, *) {
            return UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(EditingRedPacketViewController.closeBarButtonItemPressed(_:)))
        } else {
            return UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(EditingRedPacketViewController.closeBarButtonItemPressed(_:)))
        }
    }()
    private(set) lazy var nextBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(EditingRedPacketViewController.nextBarButtonItemClicked(_:)))
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
    
    let redPacketSplitTypeTableHeaderView = SelectRedPacketSplitModeTableHeaderView()
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(SelectWalletTableViewCell.self, forCellReuseIdentifier: String(describing: SelectWalletTableViewCell.self))
        
        tableView.register(InputRedPacketShareTableViewCell.self, forCellReuseIdentifier: String(describing: InputRedPacketShareTableViewCell.self))
        
        
        #if TARGET_IS_KEYBOARD
        tableView.register(KeyboardInputRedPacketAmoutCell.self, forCellReuseIdentifier: String(describing: KeyboardInputRedPacketAmoutCell.self))
        tableView.register(KeyboardInputRedPacketSenderCell.self, forCellReuseIdentifier: String(describing: KeyboardInputRedPacketSenderCell.self))
        tableView.register(KeyboardInputRedPacketMessageCell.self, forCellReuseIdentifier: String(describing: KeyboardInputRedPacketMessageCell.self))
        #else
        tableView.register(InputRedPacketAmoutTableViewCell.self, forCellReuseIdentifier: String(describing: InputRedPacketAmoutTableViewCell.self))
        tableView.register(InputRedPacketSenderTableViewCell.self, forCellReuseIdentifier: String(describing: InputRedPacketSenderTableViewCell.self))
        tableView.register(InputRedPacketMessageTableViewCell.self, forCellReuseIdentifier: String(describing: InputRedPacketMessageTableViewCell.self))
        #endif
        
        return tableView
    }()
    let walletSectionFooterView = WalletSectionFooterView()
    
    let sendRedPacketActivityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            activityIndicatorView = UIActivityIndicatorView(style: .medium)
        } else {
            activityIndicatorView = UIActivityIndicatorView(style: .white)
        }
        activityIndicatorView.stopAnimating()
        activityIndicatorView.hidesWhenStopped = true
        // use white color over blue send button
        activityIndicatorView.color = .white
        return activityIndicatorView
    }()
    lazy var sendRedPacketButton: TCActionButton = {
        let button = TCActionButton()
        button.color = .systemBlue
        button.setTitle("Send", for: .normal)
        button.setTitleColor(.white, for: .normal)
        return button
    }()

    #if TARGET_IS_EXTENSION
    weak var optionsView: OptionFieldView?
    #endif
    
    let viewModel = EditingRedPacketViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Send Red Packet"
        
        #if !TARGET_IS_KEYBOARD
        // Set close button in app
        navigationItem.leftBarButtonItem = closeBarButtonItem
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
        
        #if TARGET_IS_KEYBOARD
        // Set next button in keyboard
        navigationItem.rightBarButtonItem = nextBarButtonItem
        #else
        // Layout send red packet button in app
        sendRedPacketButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendRedPacketButton)
        let sendRedPacketButtonBottomLayoutConstraint = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: sendRedPacketButton.bottomAnchor)
        sendRedPacketButtonBottomLayoutConstraint.priority = .defaultLow
        NSLayoutConstraint.activate([
            sendRedPacketButton.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            view.layoutMarginsGuide.trailingAnchor.constraint(equalTo: sendRedPacketButton.trailingAnchor),
            sendRedPacketButtonBottomLayoutConstraint,
            view.bottomAnchor.constraint(greaterThanOrEqualTo: sendRedPacketButton.bottomAnchor, constant: 16),
        ])
        // Layout activity indicator view
        sendRedPacketActivityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        sendRedPacketButton.addSubview(sendRedPacketActivityIndicatorView)
        NSLayoutConstraint.activate([
            sendRedPacketActivityIndicatorView.centerXAnchor.constraint(equalTo: sendRedPacketButton.centerXAnchor),
            sendRedPacketActivityIndicatorView.centerYAnchor.constraint(equalTo: sendRedPacketButton.centerYAnchor),
        ])
        #endif
        
        // Bind send red packet button target & action
        sendRedPacketButton.addTarget(self, action: #selector(EditingRedPacketViewController.sendRedPacketButtonPressed(_:)), for: .touchUpInside)
        
        // Setup tableView
        tableView.tableHeaderView = redPacketSplitTypeTableHeaderView
        tableView.dataSource = viewModel
        tableView.delegate = self
        
        // Setup view model
        WalletService.default.walletModels.asDriver()
            .drive(viewModel.walletModels)
            .disposed(by: disposeBag)
        
        // Bind table view header segmented control to red packet split type
        redPacketSplitTypeTableHeaderView.modeSegmentedControl.rx.value.asDriver()
            .drive(onNext: { [weak self] index in
                guard let `self` = self else { return }
                switch index {
                case 0:
                    self.viewModel.redPacketSplitType.accept(.average)
                case 1:
                    self.viewModel.redPacketSplitType.accept(.random)
                default:
                    break
                }
            })
            .disposed(by: disposeBag)

        // Update wallet balance
        viewModel.selectWalletModel.asDriver()
            .drive(onNext: { walletModel in
                walletModel?.updateBalance()
            })
            .disposed(by: disposeBag)
        
        // Bind wallet model balance to wallet section footer view
        viewModel.selectWalletModel.asDriver()
            .flatMapLatest { walletModel -> Driver<String> in
                guard let walletModel = walletModel else {
                    return Driver.just("Current balance: - ")
                }
                
                return walletModel.balanceInDecimal.asDriver()
                    .map { decimal in
                        let placeholder = "Current balance: - "
                        guard let decimal = decimal else {
                            return placeholder
                        }
                        
                        let formatter = WalletService.balanceDecimalFormatter
                        return formatter.string(from: decimal as NSNumber).flatMap { decimalString in
                            return "Current balance: \(decimalString) ETH"
                        } ?? placeholder
                }
            }
            .drive(walletSectionFooterView.walletBalanceLabel.rx.text)
            .disposed(by: disposeBag)
        
        // Bind send red packet button text
        viewModel.sendRedPacketButtonText.asDriver()
            .drive(sendRedPacketButton.rx.title(for: .normal))
            .disposed(by: disposeBag)
        
        viewModel.isCreating.asDriver()
            .drive(onNext: { [weak self] isCreating in
                self?.tableView.isUserInteractionEnabled = !isCreating
                
                #if TARGET_IS_KEYBOARD
                self?.navigationItem.rightBarButtonItem = isCreating ? self?.activityIndicatorBarButtonItem : self?.nextBarButtonItem
                #else
                self?.navigationItem.leftBarButtonItem = isCreating ? nil : self?.closeBarButtonItem
                self?.sendRedPacketButton.isUserInteractionEnabled = !isCreating

                let buttonTitle = isCreating ? "" : "Send"
                self?.sendRedPacketButton.setTitle(buttonTitle, for: .normal)
                
                isCreating ? self?.sendRedPacketActivityIndicatorView.startAnimating() : self?.sendRedPacketActivityIndicatorView.stopAnimating()
                #endif
            })
            .disposed(by: disposeBag)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // ref: https://useyourloaf.com/blog/variable-height-table-view-header/
        guard let headerView = tableView.tableHeaderView else {
            return
        }
        
        let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height
            tableView.tableHeaderView = headerView
            tableView.layoutIfNeeded()
        }
    }
    
}

extension EditingRedPacketViewController {
 
    private func sendRedPacket() {
        view.endEditing(true)
        
        guard let selectWalletModel = viewModel.selectWalletModel.value else {
            showSendRedPacketErrorAlert(message: "Please select valid wallet")
            return
        }
        
        let senderAddress = selectWalletModel.address
        guard let walletAddress = try? EthereumAddress(hex: senderAddress, eip55: false) else {
            showSendRedPacketErrorAlert(message: "Please select valid wallet")
            return
        }
        
        guard let availableBalance = selectWalletModel.balance.value else {
            showSendRedPacketErrorAlert(message: "Can not read select wallet balance\nPlease try later")
            return
        }
        
        guard viewModel.total.value > 0,
            let sendTotal = viewModel.total.value.wei else {
                showSendRedPacketErrorAlert(message: "Please input valid amount")
                return
        }

        guard sendTotal < availableBalance else {
            showSendRedPacketErrorAlert(message: "Insufficient account balance\nPlease input valid amount")
            return
        }
        
        let senderName = viewModel.name.value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
        // should not empty
        guard !senderName.isEmpty else {
            showSendRedPacketErrorAlert(message: "Please input valid name")
            return
        }
        
        guard senderName.count <= 30 else {
            showSendRedPacketErrorAlert(message: "Name can be up to 30 characters\nPlease reduce the name length")
            return
        }
        
        // could be empty
        let sendMessage = viewModel.message.value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
        
        guard sendMessage.count <= 140 else {
            showSendRedPacketErrorAlert(message: "Messages can be up to 140 characters\nPlease reduce the message length")
            return
        }
        // Verify finish
        
        let uuids = (0..<viewModel.share.value).map { _ in
            return UUID().uuidString
        }
        assert(uuids.count == viewModel.share.value)
        let isRandom = viewModel.redPacketSplitType.value == .random
        
        let redPacket = RedPacket.v1()
        redPacket.uuids.append(objectsIn: uuids)
        redPacket.is_random = isRandom
        redPacket.sender_address = senderAddress
        redPacket.sender_name = senderName
        redPacket.send_total = sendTotal
        redPacket.send_message = sendMessage
        redPacket.status = .initial
        
        // get nonce -> call create transaction
        // success: push to CreatedRedPacketViewController
        // failure: stand in same place and just alert user error
        WalletService.getTransactionCount(address: walletAddress).asObservable()
            .withLatestFrom(viewModel.isCreating) { ($0, $1) }     // (nonce, isCreating)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .filter { $0.1 == false }                               // not creating
            .map { $0.0 }                                           // nonce
            .retry(3)
            .do(onNext: { nonce in
                let nonce = Int(nonce.quantity)
                redPacket.create_nonce.value = nonce
            })
            .flatMap { nonce -> Observable<TransactionHash> in
                return RedPacketService.create(for: redPacket, use: selectWalletModel, nonce: nonce)
                    .trackActivity(self.viewModel.createActivityIndicator)
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] transactionHash in
                do {
                    // red packet create transaction success
                    // set status to .pending
                    let realm = try RedPacketService.realm()
                    try realm.write {
                        redPacket.create_transaction_hash = transactionHash.hex()
                        redPacket.status = .pending
                        realm.add(redPacket)
                    }
                    
                    #if TARGET_IS_KEYBOARD
                    UIApplication.sharedApplication().openCreatedRedPacketView(redpacket: redPacket)
                    #else
                    let createdRedPacketViewController = CreatedRedPacketViewController()
                    createdRedPacketViewController.viewModel = CreatedRedPacketViewModel(redPacket: redPacket)
                    self?.navigationController?.pushViewController(createdRedPacketViewController, animated: true)
                    #endif
        
                } catch {
                    self?.showSendRedPacketErrorAlert(message: error.localizedDescription)
                    return
                }

            }, onError: { [weak self] error in
                // red packet create transaction fail
                // discard record and alert user
                self?.showSendRedPacketErrorAlert(message: error.localizedDescription)
            })
            .disposed(by: viewModel.disposeBag)
    }
    
    private func showSendRedPacketErrorAlert(message: String) {
        #if TARGET_IS_KEYBOARD
        KeyboardModeManager.shared.toastAlerter.alert(message: message, in: KeyboardModeManager.shared.keyboardVC!.view)
        #else
        let alertController = UIAlertController(title: "Error", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        alertController.message = message
        present(alertController, animated: true, completion: nil)
        #endif
        
    }
    
}

extension EditingRedPacketViewController {
    
    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func nextBarButtonItemClicked(_ sender: UIBarButtonItem) {
        sendRedPacket()
    }
    
    @objc private func sendRedPacketButtonPressed(_ sender: UIButton) {
        sendRedPacket()
    }
    
}

// MARK: - UITableViewDelegate
extension EditingRedPacketViewController: UITableViewDelegate {
    
    // Section Header
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }
    
    // Cell
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    // Section Footer
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let sections = viewModel.sections[section]
        
        if sections.contains(.wallet) {
            return walletSectionFooterView
        }
        
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let sections = viewModel.sections[section]
        
        if sections.contains(.wallet) {
            return UITableView.automaticDimension
        }
        
        return CGFloat.leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        #if TARGET_IS_KEYBOARD
        guard viewModel.sections[indexPath.section][indexPath.row] == .wallet else {
            return
        }
        
        let walletSelectVC = RedPacketWalletSelectViewController()
        walletSelectVC.delegate = self
        walletSelectVC.wallets = viewModel.walletModels.value
        walletSelectVC.selectedWallet = viewModel.selectWalletModel.value
        navigationController?.pushViewController(walletSelectVC, animated: true)
        #endif
    }
    
}

// MARK: - RedPacketWalletSelectViewControllerDelegate
extension EditingRedPacketViewController: RedPacketWalletSelectViewControllerDelegate {
    
    func redPacketWalletSelectViewController(_ viewController: RedPacketWalletSelectViewController, didSelect wallet: WalletModel) {
        viewModel.selectWalletModel.accept(wallet)
        viewController.navigationController?.popViewController(animated: true)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension EditingRedPacketViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return viewModel.canDismiss.value
    }
    
}

// Mock Testing Data

struct TestWallet {
    let address: String
    let amount: Int
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct EditingRedPacketViewController_Preview: PreviewProvider {
    static var previews: some View {
        let rootViewController = EditingRedPacketViewController()
        return NavigationControllerRepresenable(rootViewController: rootViewController)
    }
}
#endif
