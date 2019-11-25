//
//  EditingRedPacketViewController.swift
//  TesserCube
//
//  Created by jk234ert on 11/6/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import os
import RxSwift
import RxCocoa
import BigInt

final class EditingRedPacketViewModel: NSObject {
    
    let disposeBag = DisposeBag()
    
    enum TableViewCellType {
        case walletSelect           // select a wallet to send red packet
        case amountInput            // input the amount for send
        case splitModeSelect        // select the packet split mode (avg. or random)
        case shareInput             // input the count for shares
        case senderSelect           // select a PGP sender to mark the red packet sender

        var title: String {
            switch self {
            case .walletSelect:     return "Wallet"
            case .amountInput:      return "Amount"
            case .splitModeSelect:  return "Split"
            case .shareInput:       return "Shares"
            case .senderSelect:     return "Send as"
            }
        }
    }
    
    private let sections: [[TableViewCellType]] = [
        [.walletSelect],
        [.amountInput],
        [.splitModeSelect],
        [.shareInput],
        [.senderSelect],
    ]
    
    var redPacketProperty = RedPacketProperty()
    
    // FIXME:
    // move Input & Output out of tableViewCell
    
    // Hold all cell instance in view model
    let selectWalletTableViewCell = SelectWalletTableViewCell()
    var walletProvider: RedPacketWalletProvider?
    
    let inputRedPacketAmountTableViewCell = InputRedPacketAmoutTableViewCell()
    
    let selectRedPacketSplitModeTableViewCell = SelectRedPacketSplitModeTableViewCell()
    var splitMethodProvider: RedPacketSplitMethodProvider?
    
    let inputRedPacketShareTableViewCell = InputRedPacketShareTableViewCell()
    
    let selectRedPacketSenderTableViewCell = SelectRedPacketSenderTableViewCell()
    
    override init() {
        walletProvider = RedPacketWalletProvider(tableView: selectWalletTableViewCell.tableView, walletModels: WalletService.default.walletModels.value)
        
        splitMethodProvider = RedPacketSplitMethodProvider(redPacketProperty: redPacketProperty, tableView: selectRedPacketSplitModeTableViewCell.tableView)
        
        super.init()
        
        walletProvider?.selectWalletModel.asDriver()
            .drive(onNext: { [weak self] selectWalletModel in
                selectWalletModel?.updateBalance()
                self?.redPacketProperty.walletModel = selectWalletModel
            })
            .disposed(by: disposeBag)
        walletProvider?.selectWalletModel.asDriver()
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
                        
                        let formatter: NumberFormatter = {
                            let formatter = NumberFormatter()
                            formatter.numberStyle = .decimal
                            formatter.minimumFractionDigits = 1
                            formatter.minimumIntegerDigits = 1
                            formatter.maximumFractionDigits = 9     // percision to 1gwei
                            return formatter
                        }()
                        
                        return formatter.string(from: decimal as NSNumber).flatMap { decimalString in
                            return "Current balance: \(decimalString) ETH"
                        } ?? placeholder
                    }
            }
            .drive(selectWalletTableViewCell.walletBalanceLabel.rx.text)
            .disposed(by: disposeBag)
        inputRedPacketAmountTableViewCell.amount.asDriver()
            .drive(onNext: { [weak self] amount in
                self?.redPacketProperty.amount = amount
            })
            .disposed(by: disposeBag)
        splitMethodProvider?.selectedSplitType.asDriver()
            .drive(onNext: { [weak self] type in
                self?.redPacketProperty.splitType = type
            })
            .disposed(by: disposeBag)
        inputRedPacketShareTableViewCell.share.asDriver()
            .drive(onNext: { [weak self] share in
                self?.redPacketProperty.shareCount = share
            })
            .disposed(by: disposeBag)
        selectRedPacketSenderTableViewCell.viewModel.selectedKey.asDriver()
            .drive(onNext: { [weak self] sender in
                self?.redPacketProperty.sender = sender
            })
            .disposed(by: disposeBag)
        
        // Bind share to amount to setup validator
        inputRedPacketShareTableViewCell.share.asDriver()
            .map { Decimal($0) * Decimal(0.001) }
            .drive(inputRedPacketAmountTableViewCell.minimalAmount)
            .disposed(by: disposeBag)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

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
        let cellType = sections[indexPath.section][indexPath.row]
        let title = cellType.title
        
        switch cellType {
        case .walletSelect:
            let cell = selectWalletTableViewCell
            cell.titleLabel.text = title
            cell.detailLeadingLayoutConstraint.constant = 100
            return cell
        case .amountInput:
            let cell = inputRedPacketAmountTableViewCell
            cell.titleLabel.text = title
            cell.detailLeadingLayoutConstraint.constant = 100
            return cell
        case .splitModeSelect:
            let cell = selectRedPacketSplitModeTableViewCell
            cell.titleLabel.text = title
            cell.detailLeadingLayoutConstraint.constant = 100
            return cell
        case .shareInput:
            let cell = inputRedPacketShareTableViewCell
            cell.titleLabel.text = title
            cell.detailLeadingLayoutConstraint.constant = 100
            return cell
        case .senderSelect:
            let cell = selectRedPacketSenderTableViewCell
            cell.titleLabel.text = title
            cell.detailLeadingLayoutConstraint.constant = 100
            return cell
        }
    }
    
}

class EditingRedPacketViewController: UIViewController {
    
    let tableView: DynamicTableView = {
        let tableView = DynamicTableView()
        tableView.register(SelectWalletTableViewCell.self, forCellReuseIdentifier: String(describing: SelectWalletTableViewCell.self))
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = ._systemGroupedBackground
        tableView.separatorStyle = .none
        return tableView
    }()

    // TODO:
    weak var amountInputView: RecipientInputView? {
        return nil
    }
    
//    @IBOutlet weak var amountTitleLabel: UILabel!
//    @IBOutlet weak var splitMethodTitleLabel: UILabel!
//    @IBOutlet weak var sharesTitleLabel: UILabel!
//    @IBOutlet weak var walletTitleLabel: UILabel!
//    @IBOutlet weak var currentBalanceTitleLabel: UILabel!
//
//    @IBOutlet weak var sharesValueLabel: UILabel!
//    @IBOutlet weak var sharesStepper: UIStepper!
//
//    @IBOutlet weak var splitMethodTableView: UITableView!
//    @IBOutlet weak var walletTableView: UITableView!
//
//    @IBOutlet weak var amountInputView: RecipientInputView!
//
//    var wallets: [TestWallet] = []
//

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
        
        // Setup tableView
        tableView.dataSource = viewModel
        tableView.delegate = self
//        wallets = testWallets
//
//        configNavBar()
//        configUI()
    }
    
    private func configUI() {
//        amountInputView.inputTextField.keyboardType = .numbersAndPunctuation
//        sharesValueLabel.text = "\(redPacketProperty.sharesCount)"
    }

//    @IBAction func stepperDidClicked(_ sender: UIStepper) {
//        redPacketProperty.sharesCount = Int(sender.value)
//        configUI()
//    }
    
}

extension EditingRedPacketViewController {
    
    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func nextBarButtonItemClicked(_ sender: UIBarButtonItem) {
        view.endEditing(true)
        
        let alertController = UIAlertController(title: "Error", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        guard let selectWalletModel = viewModel.walletProvider?.selectWalletModel.value else {
            alertController.message = "Please select valid wallet"
            present(alertController, animated: true, completion: nil)
            return
        }
        
        guard let balance = selectWalletModel.balance.value else {
            alertController.message = "Wallet balance inquiry failed"
            present(alertController, animated: true, completion: nil)
            return
        }
        
        let minAmountInWei = BigUInt(viewModel.inputRedPacketShareTableViewCell.share.value) * 1000000.gwei  // 0.001 ETH
        guard balance > minAmountInWei else {
            alertController.message = "Insufficient wallet balance"
            present(alertController, animated: true, completion: nil)
            return
        }
        
        guard balance > viewModel.redPacketProperty.amountInWei else {
            alertController.message = "Insufficient wallet balance"
            present(alertController, animated: true, completion: nil)
            return
        }
        
        let selectRecipientsVC = RedPacketRecipientSelectViewController()
        selectRecipientsVC.redPacketProperty = viewModel.redPacketProperty
        //        recommendView?.updateColor(theme: currentTheme)
        #if TARGET_IS_EXTENSION
        selectRecipientsVC.delegate = KeyboardModeManager.shared
        selectRecipientsVC.optionFieldView = optionsView
        #else
        selectRecipientsVC.delegate = self
        #endif
        navigationController?.pushViewController(selectRecipientsVC, animated: true)
    }
    
}

// MARK: - UITableViewDelegate
extension EditingRedPacketViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }
    
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension EditingRedPacketViewController: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .fullScreen
    }
    
}

// MAKR: - RedPacketRecipientSelectViewControllerDelegate
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

// Mock Testing Data

struct TestWallet {
    let address: String
    let amount: Int
}
//extension EditingRedPacketViewController {
//    var testWallets: [TestWallet] {
//        return [
//            TestWallet(address: "0x1191", amount: 25),
//            TestWallet(address: "0x3389", amount: 35)
//        ]
//    }
//}

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
