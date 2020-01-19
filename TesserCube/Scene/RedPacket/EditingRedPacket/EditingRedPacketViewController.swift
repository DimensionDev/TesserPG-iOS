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
import Web3
import RxSwiftUtilities

final class EditingRedPacketViewModel: NSObject {
    
    let disposeBag = DisposeBag()
    let createActivityIndicator = ActivityIndicator()
    
    // Input
    let redPacketSplitType = BehaviorRelay(value: SplitType.average)
    
    let walletModels = BehaviorRelay<[WalletModel]>(value: [])
    let selectWalletModel = BehaviorRelay<WalletModel?>(value: nil)
    let selectTokenType = BehaviorRelay(value: RedPacketTokenSelectViewModel.SelectTokenType.eth)
    
    let amount = BehaviorRelay(value: Decimal(0))       // user input value. default 0
    let share = BehaviorRelay(value: 1)
    
    let name = BehaviorRelay(value: "")
    let message = BehaviorRelay(value: "")
    
    // Output
    let isCreating = BehaviorRelay(value: false)
    let canDismiss = BehaviorRelay(value: true)
    
    let minimalAmount = BehaviorRelay(value: RedPacketService.redPacketMinAmount)
    let totalInDecimal = BehaviorRelay(value: Decimal(0))     // should not 0 after user input amount
    let selectTokenDecimal = BehaviorRelay(value: 18)         // default 18 for ETH
    let walletBalanceForSelectToken = BehaviorRelay<BigUInt?>(value: nil)
    
    // "Current balance: <token_in_decimal> <token_symbol>"
    // Combine `walletBalanceForSelectToken` and `selectTokenType` to drive
    let walletSectionFooterViewText: Driver<String>
    
    // "<token_symbol> per share" or "<token_symbol>"
    // Combine `redPacketSplitType` and `selectTokenType` to drive
    let amountInputCoinCurrencyUnitLabelText: Driver<String>
    
    // "Send <send_total_amount_in_decimal> <token_symbol>"
    // Combine `totalInDecimal` and `selectTokenType`
    let sendRedPacketButtonText: Driver<String>
    
    enum TableViewCellType {
        case wallet                 // select a wallet to send red packet
        case token                  // select token type
        case amount                 // input the amount for send
        case share                  // input the count for shares
        case name                   // input the sender name
        case message                // input the comment message
    }
    
    let sections: [[TableViewCellType]] = [
        [
            .wallet,
            .token,
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
        createActivityIndicator
            .asDriver()
            .drive(isCreating)
            .disposed(by: disposeBag)
        amountInputCoinCurrencyUnitLabelText = Driver.combineLatest(redPacketSplitType.asDriver(), selectTokenType.asDriver()) { (redPacketSplitType, selectTokenType) -> String in
            let symbol: String
            switch selectTokenType {
            case .eth: symbol = "ETH"
            case .erc20(let walletToken):
                symbol = walletToken.token?.symbol ?? ""
            }
            
            return redPacketSplitType == .average ? "\(symbol) per share" : symbol
        }
        selectTokenType.asDriver()
            .withLatestFrom(selectWalletModel.asDriver()) {
                return ($0, $1)
        }
        .flatMapLatest { (selectTokenType, selectWalletModel) -> Driver<BigUInt?> in
            guard let walletModel = selectWalletModel else {
                return Driver.just(nil)
            }
            switch selectTokenType {
            case .eth:
                return walletModel.balance.asDriver()
            case .erc20(let walletToken):
                return Observable.from(object: walletToken)
                    .map { $0.balance }
                    .asDriver(onErrorJustReturn: nil)
            }
        }
        .drive(walletBalanceForSelectToken)
        .disposed(by: disposeBag)
        selectTokenType.asDriver()
            .map { tokenType in
                switch tokenType {
                case .eth:                      return 18
                case .erc20(let walletToken):   return walletToken.token?.decimals ?? 0
                }
        }
        .drive(selectTokenDecimal)
        .disposed(by: disposeBag)
        selectTokenType.asDriver()
            .map { tokenType -> Decimal in
                switch tokenType {
                case .eth:                      return RedPacketService.redPacketMinAmount
                case .erc20(let walletToken):
                    guard let decimals = walletToken.token?.decimals else {
                        return RedPacketService.redPacketMinAmount
                    }
                    
                    return 1 / pow(10, (decimals + 1) / 2)
                }
        }
        .drive(minimalAmount)
        .disposed(by: disposeBag)
        walletSectionFooterViewText = Driver.combineLatest(walletBalanceForSelectToken.asDriver(), selectTokenType.asDriver()) { (walletBalanceForSelectToken, selectTokenType) -> String in
            let placeholder = "Current balance: - "
            
            let decimals: Int
            let symbol: String
            switch selectTokenType {
            case .eth:
                decimals = 18
                symbol = "ETH"
            case let .erc20(walletToken):
                guard let token = walletToken.token else {
                    return placeholder
                }
                
                decimals = token.decimals
                symbol = token.symbol
            }
            
            let _balanceInDecimal = walletBalanceForSelectToken
                .flatMap { Decimal(string: String($0)) }
                .map { balance in balance / pow(10, decimals) }
            
            guard let balanceInDecimal = _balanceInDecimal else {
                return placeholder
            }
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumIntegerDigits = 1
            formatter.maximumFractionDigits = (decimals + 1) / 2
            formatter.groupingSeparator = ""
            
            return formatter.string(from: balanceInDecimal as NSNumber).flatMap { decimalString in
                return "Current balance: \(decimalString) \(symbol)"
                } ?? placeholder
        }
        sendRedPacketButtonText = Driver.combineLatest(totalInDecimal.asDriver(), selectTokenType.asDriver()) { (totalInDecimal, selectTokenType) -> String in
            switch selectTokenType {
            case .eth:
                guard totalInDecimal > 0, let totalInETH = NumberFormatter.decimalFormatterForETH.string(from: totalInDecimal as NSNumber) else {
                    return "Send"
                }
                
                return "Send \(totalInETH) ETH"
            case .erc20(let walletToken):
                guard let token = walletToken.token else {
                    return "Send"
                }
                
                let formatter = NumberFormatter.decimalFormatterForToken(decimals: token.decimals)
                guard totalInDecimal > 0, let tokenInSymbol = formatter.string(from: totalInDecimal as NSNumber) else {
                    return "Send"
                }
                
                return "Send \(tokenInSymbol) \(token.symbol)"
            }
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
        .drive(totalInDecimal)
        .disposed(by: disposeBag)
        
        isCreating.asDriver()
            .map { !$0 }
            .drive(canDismiss)
            .disposed(by: disposeBag)
        
        // Reset select token type to .eth when select new wallet
        selectWalletModel.asDriver()
            .drive(onNext: { [weak self] _ in
                self?.selectTokenType.accept(.eth)
            })
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

            walletModels.bind(to: _cell.walletPickerView.rx.items) { index, item, view in
                let label = (view as? UILabel) ?? UILabel()
                label.textAlignment = .center
                label.adjustsFontSizeToFitWidth = true
                label.text = "Wallet \(item.address.prefix(6))"
                return label
            }
            .disposed(by: _cell.disposeBag)
            
            #if !TARGET_IS_KEYBOARD
            _cell.walletPickerView.rx.modelSelected(WalletModel.self)
                .asDriver()
                .map { $0.first }
                .drive(selectWalletModel)
                .disposed(by: disposeBag)
            #endif
//            _cell.walletPickerView.rx.modelSelected(WalletModel.self)
//
//                .asDriver()
//                .drive(selectWalletModel)
//                .disposed(by: _cell.disposeBag)
//
            selectWalletModel.asDriver()
                .map { walletModel in
                    guard let walletModel = walletModel else {
                        return L10n.Common.Label.nameNone
                    }

                    return "Wallet \(walletModel.address.prefix(6))"
                }
                .drive(_cell.walletTextField.rx.text)
                .disposed(by: _cell.disposeBag)
            
            cell = _cell
            
        case .token:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SelectTokenTableViewCell.self), for: indexPath) as! SelectTokenTableViewCell
            selectTokenType.asDriver()
                .map { type -> String in
                    switch type {
                    case .eth:                      return "ETH"
                    case let .erc20(walletToken):   return walletToken.token?.name ?? "-"
                    }
                }
                .drive(_cell.tokenNameTextField.rx.text)
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


// [RP_Mode]:           segmented control with two segments: [.average, .random]
// [RP_Wallet]:         selected wallet for send RP
// [RP_Token]:          token type: [.eth, .erc20(WalletToken)]. Default .eth
// [UI_CurrentBalance]: label: "Current balance: <token_in_decimal> <token_symbol>"
// [RP_Amount]:         send amount in decimal.
//                      format with token <(decimals + 1) / 2> for .maximumFractionDigits.
// [UI_Amount_Hint]:    label: "<symbol per share>" (.average mode) or "<token_symbol>" (.random mode)
// [RP_Share]:          send share count. 1...100
// [RP_Name]:           one-line trimmed sender name. Max up to 30 (include) chars. Not empty
// [RP_Message]:        one-line trimmed message. Max up to 140 (include) chars. Could empty
// [UI_SendButton]:     button: "Send <send_total_amoun_in_decimal> <token_symbol>"
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
        tableView.register(SelectTokenTableViewCell.self, forCellReuseIdentifier: String(describing: SelectTokenTableViewCell.self))
        
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
        viewModel.walletSectionFooterViewText.asDriver()
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
        
        guard let availableBalance = viewModel.walletBalanceForSelectToken.value else {
            showSendRedPacketErrorAlert(message: "Can not read select wallet balance\nPlease try later")
            return
        }
        
        let sendTotalInDecimal = viewModel.totalInDecimal.value
        guard viewModel.totalInDecimal.value > 0,
        let sendTotalInBigUInt = sendTotalInDecimal.tokenInBigUInt(for: viewModel.selectTokenDecimal.value) else {
            showSendRedPacketErrorAlert(message: "Please input valid amount")
            return
        }
    
        guard sendTotalInBigUInt < availableBalance else {
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
        
        let redPacket = RedPacket.v1(for: EthereumPreference.ethereumNetwork)
        redPacket.uuids.append(objectsIn: uuids)
        redPacket.is_random = isRandom
        redPacket.sender_address = senderAddress
        redPacket.sender_name = senderName
        redPacket.send_total = sendTotalInBigUInt
        redPacket.send_message = sendMessage
        redPacket.status = .initial
        
        let selectWalletValue = WalletValue(from: selectWalletModel)
        
        // Init web3
        let network = redPacket.network
        let web3 = Web3Secret.web3(for: network)
        
        let tokenType = viewModel.selectTokenType.value
        switch tokenType {
        case .eth:
            // get nonce -> call create transaction
            // success: push to CreatedRedPacketViewController
            // failure: stand in same place and just alert user error
            WalletService.getTransactionCount(address: walletAddress, web3: web3).asObservable()
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
                    return RedPacketService.shared.create(for: redPacket, use: selectWalletValue, nonce: nonce)
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
                        createdRedPacketViewController.viewModel = CreatedRedPacketViewModel(redPacket: redPacket, walletModel: selectWalletModel)
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
            
        case .erc20(walletToken: let walletToken):
            guard let token = walletToken.token else {
                showSendRedPacketErrorAlert(message: "Cannot retrieve token entity")
                return
            }
                        
            let tokenID = token.id
            redPacket.token_type = .erc20
            redPacket.erc20_token = token
            
            WalletService.getTransactionCount(address: walletAddress, web3: web3).asObservable()
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .retry(3)
                .do(onNext: { nonce in
                    let nonce = Int(nonce.quantity)
                    redPacket.create_nonce.value = nonce
                })
                .flatMap { nonce -> Observable<TransactionHash> in
                    do {
                        let realm = try RedPacketService.realm()
                        guard let token = realm.object(ofType: ERC20Token.self, forPrimaryKey: tokenID) else {
                            return Observable.error(RedPacketService.Error.internal("cannot retrieve token"))
                        }
                        return RedPacketService.approve(for: redPacket, use: selectWalletModel, on: token, nonce: nonce)
                            .trackActivity(self.viewModel.createActivityIndicator)
                    } catch {
                        return Observable.error(error)
                    }
                }
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] transactionHash in
                    do {
                        // red packet token approve success
                        let realm = try RedPacketService.realm()
                        try realm.write {
                            redPacket.erc20_approve_transaction_hash = transactionHash.hex()
                            redPacket.status = .pending
                            realm.add(redPacket)
                        }
            
                        let createdRedPacketViewController = CreatedRedPacketViewController()
                        createdRedPacketViewController.viewModel = CreatedRedPacketViewModel(redPacket: redPacket, walletModel: selectWalletModel)
                        self?.navigationController?.pushViewController(createdRedPacketViewController, animated: true)
                        
                    } catch {
                        self?.showSendRedPacketErrorAlert(message: error.localizedDescription)
                    }
                }, onError: { [weak self] error in
                    // red packet create transaction fail
                    // discard record and alert user
                    self?.showSendRedPacketErrorAlert(message: error.localizedDescription)
                })
                .disposed(by: viewModel.disposeBag)
        }
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
        switch viewModel.sections[indexPath.section][indexPath.row] {
        case .wallet:
            #if TARGET_IS_KEYBOARD
            let walletSelectVC = RedPacketWalletSelectViewController()
            walletSelectVC.delegate = self
            walletSelectVC.wallets = viewModel.walletModels.value
            walletSelectVC.selectedWallet = viewModel.selectWalletModel.value
            navigationController?.pushViewController(walletSelectVC, animated: true)
            #else
            break
            #endif

        case .token:
            guard let walletModel = self.viewModel.selectWalletModel.value else {
                return
            }
            
            let tokenSelectViewController = RedPacketTokenSelectViewController()
            let viewModel = RedPacketTokenSelectViewModel(walletModel: walletModel)
            tokenSelectViewController.viewModel = viewModel
            tokenSelectViewController.delegate = self
            navigationController?.presentationController?.delegate = tokenSelectViewController as UIAdaptivePresentationControllerDelegate
            navigationController?.pushViewController(tokenSelectViewController, animated: true)
        default:
            break
        }
    }
    
}

// MARK: - RedPacketWalletSelectViewControllerDelegate
extension EditingRedPacketViewController: RedPacketWalletSelectViewControllerDelegate {
    
    func redPacketWalletSelectViewController(_ viewController: RedPacketWalletSelectViewController, didSelect wallet: WalletModel) {
        viewModel.selectWalletModel.accept(wallet)
        viewController.navigationController?.popViewController(animated: true)
    }
    
}

// MARK: - RedPacketTokenSelectViewControllerDelegate
extension EditingRedPacketViewController: RedPacketTokenSelectViewControllerDelegate {
    
    func redPacketTokenSelectViewController(_ viewController: RedPacketTokenSelectViewController, didSelectTokenType selectTokenType: RedPacketTokenSelectViewModel.SelectTokenType) {
        viewModel.selectTokenType.accept(selectTokenType)
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
