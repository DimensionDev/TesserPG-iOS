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
        
        tableView.register(InputRedPacketAmoutTableViewCell.self, forCellReuseIdentifier: String(describing: InputRedPacketAmoutTableViewCell.self))
        tableView.register(InputRedPacketShareTableViewCell.self, forCellReuseIdentifier: String(describing: InputRedPacketShareTableViewCell.self))
        
        tableView.register(InputRedPacketSenderTableViewCell.self, forCellReuseIdentifier: String(describing: InputRedPacketSenderTableViewCell.self))
        tableView.register(InputRedPacketMessageTableViewCell.self, forCellReuseIdentifier: String(describing: InputRedPacketMessageTableViewCell.self))
        
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

    // TODO:
    weak var amountInputView: KeyboardInputView? {
        return nil
    }

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
        
        let alertController = UIAlertController(title: "Error", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        guard let selectWalletModel = viewModel.selectWalletModel.value else {
            alertController.message = "Please select valid wallet"
            present(alertController, animated: true, completion: nil)
            return
        }
        
        let senderAddress = selectWalletModel.address
        guard let walletAddress = try? EthereumAddress(hex: senderAddress, eip55: false) else {
            alertController.message = "Please select valid wallet"
            present(alertController, animated: true, completion: nil)
            return
        }
        
        guard let availableBalance = viewModel.walletBalanceForSelectToken.value else {
            alertController.message = "Can not read select wallet balance\nPlease try later"
            present(alertController, animated: true, completion: nil)
            return
        }
        
        let sendTotalInDecimal = viewModel.totalInDecimal.value
        guard viewModel.totalInDecimal.value > 0,
        let sendTotalInBigUInt = sendTotalInDecimal.tokenInBigUInt(for: viewModel.selectTokenDecimal.value) else {
            alertController.message = "Please input valid amount"
            present(alertController, animated: true, completion: nil)
            return
        }
    
        guard sendTotalInBigUInt < availableBalance else {
            alertController.message = "Insufficient account balance\nPlease input valid amount"
            present(alertController, animated: true, completion: nil)
            return
        }
        
        let senderName = viewModel.name.value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
        // should not empty
        guard !senderName.isEmpty else {
            alertController.message = "Please input valid name"
            present(alertController, animated: true, completion: nil)
            return
        }
        
        guard senderName.count <= 30 else {
            alertController.message = "Name can be up to 30 characters\nPlease reduce the name length"
            present(alertController, animated: true, completion: nil)
            return
        }
        
        // could be empty
        let sendMessage = viewModel.message.value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
        
        guard sendMessage.count <= 140 else {
            alertController.message = "Messages can be up to 140 characters\nPlease reduce the message length"
            present(alertController, animated: true, completion: nil)
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
        redPacket.send_total = sendTotalInBigUInt
        redPacket.send_message = sendMessage
        redPacket.status = .initial
        
        let selectWalletValue = WalletValue(from: selectWalletModel)
        
        let tokenType = viewModel.selectTokenType.value
        switch tokenType {
        case .eth:
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
                        
                        let createdRedPacketViewController = CreatedRedPacketViewController()
                        createdRedPacketViewController.viewModel = CreatedRedPacketViewModel(redPacket: redPacket, walletModel: selectWalletModel)
                        self?.navigationController?.pushViewController(createdRedPacketViewController, animated: true)
                        
                    } catch {
                        alertController.message = error.localizedDescription
                        self?.present(alertController, animated: true, completion: nil)
                        return
                    }
                    
                }, onError: { [weak self] error in
                    // red packet create transaction fail
                    // discard record and alert user
                    alertController.message = error.localizedDescription
                    self?.present(alertController, animated: true, completion: nil)
                })
                .disposed(by: viewModel.disposeBag)
            
        case .erc20(walletToken: let walletToken):
            guard let token = walletToken.token else {
                alertController.message = "Cannot retrieve token entity"
                self.present(alertController, animated: true, completion: nil)
                return
            }
                        
            let tokenID = token.id
            redPacket.token_type = .erc20
            redPacket.erc20_token = token
            
            WalletService.getTransactionCount(address: walletAddress).asObservable()
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
                        alertController.message = error.localizedDescription
                        self?.present(alertController, animated: true, completion: nil)
                        return
                    }
                }, onError: { [weak self] error in
                    // red packet create transaction fail
                    // discard record and alert user
                    alertController.message = error.localizedDescription
                    self?.present(alertController, animated: true, completion: nil)
                })
                .disposed(by: viewModel.disposeBag)

            // RedPacketService.approve(for: redPacket, use: selectWalletModel, on: token, nonce: nonce)
        }
        
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
