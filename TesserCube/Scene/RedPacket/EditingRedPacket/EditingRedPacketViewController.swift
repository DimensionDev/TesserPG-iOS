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
import BigInt
import DMS_HDWallet_Cocoa

final class EditingRedPacketViewModel: NSObject {
    
    let disposeBag = DisposeBag()
    
    // Input
    let redPacketSplitType = BehaviorRelay(value: SplitType.average)
    
    let walletModels = BehaviorRelay<[WalletModel]>(value: [])
    let selectWalletModel = BehaviorRelay<WalletModel?>(value: nil)
    
    let amount = BehaviorRelay(value: Decimal(0))       // user input value. default 0
    let share = BehaviorRelay(value: 1)
    
    let name = BehaviorRelay(value: "")
    let message = BehaviorRelay(value: "")
    
    // Output
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
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: InputRedPacketAmoutTableViewCell.self), for: indexPath) as! InputRedPacketAmoutTableViewCell
            
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
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: InputRedPacketSenderTableViewCell.self), for: indexPath) as! InputRedPacketSenderTableViewCell
            
            _cell.nameTextField.rx.text.orEmpty.asDriver()
                .drive(name)
                .disposed(by: _cell.disposeBag)
            
            cell = _cell
            
        case .message:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: InputRedPacketMessageTableViewCell.self), for: indexPath) as! InputRedPacketMessageTableViewCell
            
            _cell.messageTextField.rx.text.orEmpty.asDriver()
                .drive(message)
                .disposed(by: _cell.disposeBag)
            
            cell = _cell
        }
        
        return cell
    }
    
}

class EditingRedPacketViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    let redPacketSplitTypeTableHeaderView = SelectRedPacketSplitModeTableHeaderView()
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(SelectWalletTableViewCell.self, forCellReuseIdentifier: String(describing: SelectWalletTableViewCell.self))
        
        tableView.register(InputRedPacketAmoutTableViewCell.self, forCellReuseIdentifier: String(describing: InputRedPacketAmoutTableViewCell.self))
        tableView.register(InputRedPacketShareTableViewCell.self, forCellReuseIdentifier: String(describing: InputRedPacketShareTableViewCell.self))
        
        tableView.register(InputRedPacketSenderTableViewCell.self, forCellReuseIdentifier: String(describing: InputRedPacketSenderTableViewCell.self))
        tableView.register(InputRedPacketMessageTableViewCell.self, forCellReuseIdentifier: String(describing: InputRedPacketMessageTableViewCell.self))
        
        return tableView
    }()
    let walletSectionFooterView = WalletSectionFooterView()
    
    let sendRedPacketButton: TCActionButton = {
        let button = TCActionButton()
        button.color = .systemBlue
        button.setTitle("Send", for: .normal)
        button.setTitleColor(.white, for: .normal)
        return button
    }()

    // TODO:
    weak var amountInputView: RecipientInputView? {
        return nil
    }

    #if TARGET_IS_EXTENSION
    weak var optionsView: OptionFieldView?
    #endif
    
    let viewModel = EditingRedPacketViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Send Red Packet"
        #if !TARGET_IS_EXTENSION
        if #available(iOS 13.0, *) {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(EditingRedPacketViewController.closeBarButtonItemPressed(_:)))
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(EditingRedPacketViewController.closeBarButtonItemPressed(_:)))
        }
        #endif
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(EditingRedPacketViewController.nextBarButtonItemClicked(_:)))
    
        // Layout tableView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        // Layout send red packet button
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
        
        let alertController = UIAlertController(title: "Error", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        guard let selectWalletModel = viewModel.selectWalletModel.value else {
            alertController.message = "Please select valid wallet"
            present(alertController, animated: true, completion: nil)
            return
        }
        let senderAddress = selectWalletModel.address
        
        guard let availableBalance = selectWalletModel.balance.value else {
            alertController.message = "Can not read select wallet balance\nPlease try later"
            present(alertController, animated: true, completion: nil)
            return
        }
        
        guard viewModel.total.value > 0,
            let sendTotal = viewModel.total.value.wei else {
                alertController.message = "Please input valid amount"
                present(alertController, animated: true, completion: nil)
                return
        }

        guard sendTotal < availableBalance else {
            alertController.message = "Insufficient account balance\nPlease input valid amout"
            present(alertController, animated: true, completion: nil)
            return
        }
        
        let senderName = viewModel.name.value.trimmingCharacters(in: .whitespacesAndNewlines)
        // should not empty
        guard !senderName.isEmpty else {
            alertController.message = "Please input valid name"
            present(alertController, animated: true, completion: nil)
            return
        }
        
        // could be empty
        let sendMessage = viewModel.message.value.trimmingCharacters(in: .whitespacesAndNewlines)
            
        // Verify finish
        
        let uuids = (0..<viewModel.share.value).map { _ in
            return UUID().uuidString
        }
        assert(uuids.count == viewModel.share.value)
        let isRandom = viewModel.redPacketSplitType.value == .random
        
        do {
            let redPacket = RedPacket.v1()
            redPacket.uuids.append(objectsIn: uuids)
            redPacket.is_random = isRandom
            redPacket.sender_address = senderAddress
            redPacket.sender_name = senderName
            redPacket.send_total = sendTotal
            redPacket.send_message = sendMessage
            redPacket.status = .initial
            
            let realm = try RedPacketService.realm()
            try realm.write {
                realm.add(redPacket)
            }
        } catch {
            alertController.message = error.localizedDescription
            return
        }
    }
    
}

extension EditingRedPacketViewController {
    
    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func nextBarButtonItemClicked(_ sender: UIBarButtonItem) {
        sendRedPacket()
//        guard let balance = selectWalletModel.balance.value else {
//            alertController.message = "Wallet balance inquiry failed"
//            present(alertController, animated: true, completion: nil)
//            return
//        }
//
//        let minAmountInWei = BigUInt(viewModel.inputRedPacketShareTableViewCell.share.value) * WalletService.redPacketMinAmountInWei
//        guard balance > minAmountInWei else {
//            alertController.message = "Insufficient wallet balance"
//            present(alertController, animated: true, completion: nil)
//            return
//        }
//
//        guard balance > viewModel.redPacketProperty.amountInWei else {
//            alertController.message = "Insufficient wallet balance"
//            present(alertController, animated: true, completion: nil)
//            return
//        }
//
//        // FIXME:
//        let minAmountDecimal = (Decimal(string: String(minAmountInWei)) ?? Decimal(0)) / HDWallet.CoinType.ether.exponent
//        if viewModel.redPacketProperty.amount < minAmountDecimal {
//            viewModel.redPacketProperty.amount = minAmountDecimal
//        }
//
//        let selectRecipientsVC = RedPacketRecipientSelectViewController()
//        selectRecipientsVC.redPacketProperty = viewModel.redPacketProperty
//        //        recommendView?.updateColor(theme: currentTheme)
//        #if TARGET_IS_EXTENSION
//        selectRecipientsVC.delegate = KeyboardModeManager.shared
//        selectRecipientsVC.optionFieldView = optionsView
//        #else
//        selectRecipientsVC.delegate = self
//        #endif
//        navigationController?.pushViewController(selectRecipientsVC, animated: true)
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
    
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension EditingRedPacketViewController: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .fullScreen
    }
    
}

// MAKR: - RedPacketRecipientSelectViewControllerDelegate
/*
extension EditingRedPacketViewController: RedPacketRecipientSelectViewControllerDelegate {
    
    func redPacketRecipientSelectViewController(_ viewController: RedPacketRecipientSelectViewController, didSelect contactInfo: FullContactInfo) {
        let isContains = viewModel.redPacketProperty.contactInfos.contains { $0.contact.id == contactInfo.contact.id }
        guard !isContains else {
            return
        }
        
        viewModel.redPacketProperty.contactInfos.append(contactInfo)
    }
    
    func redPacketRecipientSelectViewController(_ viewController: RedPacketRecipientSelectViewController, didDeselect contactInfo: FullContactInfo) {
        viewModel.redPacketProperty.contactInfos.removeAll { $0.contact.id == contactInfo.contact.id }
    }
    
}
 */

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
