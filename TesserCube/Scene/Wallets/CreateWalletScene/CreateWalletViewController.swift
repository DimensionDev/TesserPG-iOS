//
//  CreateWalletViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-6.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import DMS_HDWallet_Cocoa

class CreateWalletViewModel {

    public let passpharse = BehaviorRelay(value: "")
    public let confirmPasspharse = BehaviorRelay(value: "")

    init() {

    }

}

class CreateWalletViewController: TCBaseViewController {

    private let viewModel = CreateWalletViewModel()

    enum TableViewCellType {
        case passphrase
        case confirmPassphrase
    }

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.keyboardDismissMode = .interactive
        tableView.register(PasswordTextFieldTableViewCell.self, forCellReuseIdentifier: String(describing: PasswordTextFieldTableViewCell.self))
        return tableView
    }()

    private let sections: [[TableViewCellType]] = [
       [
           .passphrase,
           .confirmPassphrase,
        ],
    ]

    private var createWalletButtonBottomLayoutMarginLayoutConstraint: NSLayoutConstraint!
    private let createWalletButton: TCActionButton = {
        let button = TCActionButton()
        button.color = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Create Wallet", for: .normal)
        return button
    }()

    override func configUI() {
        super.configUI()

        title = "Create Wallet"
        if #available(iOS 13.0, *) {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(CreateWalletViewController.closeBarButtonItemPressed(_:)))
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(CreateWalletViewController.closeBarButtonItemPressed(_:)))
        }

        // Layout
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Setup tableView
        tableView.dataSource = self
        tableView.delegate = self

        // Layout Button
        createWalletButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(createWalletButton)

        let createWalletButtonBottomLayoutConstraint = view.bottomAnchor.constraint(greaterThanOrEqualTo: createWalletButton.bottomAnchor, constant: 16)
        createWalletButtonBottomLayoutMarginLayoutConstraint = view.layoutMarginsGuide.bottomAnchor.constraint(equalTo: createWalletButton.bottomAnchor)
        createWalletButtonBottomLayoutMarginLayoutConstraint.priority = .defaultLow
        NSLayoutConstraint.activate([
            createWalletButton.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            createWalletButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            createWalletButtonBottomLayoutMarginLayoutConstraint,
            createWalletButtonBottomLayoutConstraint,
        ])

        // Bind button action
        createWalletButton.addTarget(self, action: #selector(CreateWalletViewController.createWalletButtonPressed(_:)), for: .touchUpInside)
    }

}

extension CreateWalletViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PasswordTextFieldTableViewCell else {
            return
        }

        cell.passphraseTextField.becomeFirstResponder()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        // createWalletButtonBottomLayoutConstraint.constant = view.safeAreaInsets.bottom
    }

}

extension CreateWalletViewController {

    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @objc private func createWalletButtonPressed(_ sender: UIButton) {
        guard viewModel.passpharse.value == viewModel.confirmPasspharse.value else {
            let alertController = UIAlertController(title: "Error", message: "Password didn't match.\nTry again.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: L10n.Common.Button.ok, style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
            return
        }

        let mnemonic = Mnemonic.create()
        let wallet = Wallet(mnemonic: mnemonic, passphrase: viewModel.passpharse.value)
        WalletService.default.append(wallet: wallet)

        let viewModel = BackupMnemonicCollectionViewModel(wallet: wallet)
        Coordinator.main.present(scene: .backupMnemonic(viewModel: viewModel), from: self, transition: .detail, completion: nil)
    }

}

// MARK: - UITableViewDataSource
extension CreateWalletViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section][indexPath.row] {
        case .passphrase:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PasswordTextFieldTableViewCell.self), for: indexPath) as! PasswordTextFieldTableViewCell
            cell.passphraseTextField.placeholder = "Set Password"

            return cell
        case .confirmPassphrase:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PasswordTextFieldTableViewCell.self), for: indexPath) as! PasswordTextFieldTableViewCell
            cell.passphraseTextField.placeholder = "Confirm Password"

            return cell
        }
    }

}

// MARK: - UITableViewDelegate
extension CreateWalletViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? PasswordTextFieldTableViewCell else {
            fatalError()
        }

        switch sections[indexPath.section][indexPath.row] {
        case .passphrase:
            cell.passphraseTextField.rx.text.orEmpty.bind(to: viewModel.passpharse).disposed(by: cell.disposeBag)

        case .confirmPassphrase:
            cell.passphraseTextField.rx.text.orEmpty.bind(to: viewModel.confirmPasspharse).disposed(by: cell.disposeBag)
        }
    }

}

// MARK: - UIAdaptivePresentationControllerDelegate
extension CreateWalletViewController: UIAdaptivePresentationControllerDelegate {

    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return traitCollection.horizontalSizeClass == .compact ? .fullScreen : .pageSheet
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }

}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct CreateWalletViewController_Previews: PreviewProvider {
    static var previews: some View {
        NavigationControllerRepresenable(rootViewController: CreateWalletViewController())
    }
}

#endif
