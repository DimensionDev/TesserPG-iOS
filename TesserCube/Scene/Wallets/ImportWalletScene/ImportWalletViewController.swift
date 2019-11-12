//
//  ImportWalletViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-8.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import DMS_HDWallet_Cocoa

class ImportWalletViewController: TCBaseViewController {

    private let disposeBag = DisposeBag()

    // Fix iPhone SE keyboard overlap issue
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.preservesSuperviewLayoutMargins = true
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    private var scrollViewContentLayoutGuideHeight: NSLayoutConstraint!
    private var scrollViewContentLayoutGuideBottomToDoneButtonBottom: NSLayoutConstraint!

    let passwordTableViewCell = PasswordTextFieldTableViewCell()
    let passwordTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.isScrollEnabled = false
        tableView.register(PasswordTextFieldTableViewCell.self, forCellReuseIdentifier: String(describing: PasswordTextFieldTableViewCell.self))
        return tableView
    }()

    // let passphraseTextField = PassphraseTextField()
    let importButton: TCActionButton = {
        let button = TCActionButton()
        button.color = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Import Wallet", for: .normal)
        return button
    }()
    let activityIndicatorView = UIActivityIndicatorView(style: .white)

    let viewModel = ImportMnemonicCollectionViewModel()
    lazy var mnemonicCollectionView: MnemonicCollectionView = {
        let collectionView = MnemonicCollectionView(viewModel: viewModel)
        viewModel.collectionView = collectionView
        return collectionView
    }()

    override func configUI() {
        super.configUI()

        title = "Mnemonic Words"
        if #available(iOS 13.0, *) {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(ImportWalletViewController.closeBarButtonItemPressed(_:)))
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(ImportWalletViewController.closeBarButtonItemPressed(_:)))
        }
        view.backgroundColor = ._systemGroupedBackground

        // Layout content scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        scrollViewContentLayoutGuideHeight = scrollView.contentLayoutGuide.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)

        // Layout input mnemonic collection view
        mnemonicCollectionView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(mnemonicCollectionView)
        NSLayoutConstraint.activate([
            mnemonicCollectionView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            mnemonicCollectionView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: mnemonicCollectionView.trailingAnchor, constant: 16),
            mnemonicCollectionView.heightAnchor.constraint(equalToConstant: MnemonicCollectionView.height),
        ])
        mnemonicCollectionView.setContentHuggingPriority(.defaultLow, for: .vertical)
        mnemonicCollectionView.setContentCompressionResistancePriority(.required, for: .vertical)

        // Layout password tableView
        passwordTableView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(passwordTableView)
        NSLayoutConstraint.activate([
            passwordTableView.topAnchor.constraint(equalTo: mnemonicCollectionView.bottomAnchor),
            passwordTableView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            passwordTableView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            passwordTableView.heightAnchor.constraint(equalToConstant: 20 + 44 + 20),
        ])

        // Layout import button
        importButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(importButton)
        scrollViewContentLayoutGuideBottomToDoneButtonBottom = scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: importButton.bottomAnchor, constant: 0)
        NSLayoutConstraint.activate([
            importButton.topAnchor.constraint(greaterThanOrEqualTo: passwordTableView.bottomAnchor, constant: 20),
            importButton.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            importButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            importButton.heightAnchor.constraint(equalToConstant: 50),
            scrollViewContentLayoutGuideBottomToDoneButtonBottom
        ])
        // Layout activity idecator over imoprt button
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: importButton.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: importButton.centerYAnchor),
        ])

        //importButton.setTitle(L10n.ImportMemonicViewController.ImportButton.title, for: .normal)
        //importButton.addTarget(self, action: #selector(ImportMemonicViewController.importButtonPressed(_:)), for: .touchUpInside)

//        passphraseTextField.isSecureTextEntry = true
//        passphraseTextField.keyboardType = .asciiCapable
//        passphraseTextField.autocorrectionType = .no
//        passphraseTextField.autocapitalizationType = .none
//        passphraseTextField.enablesReturnKeyAutomatically = true
//        passphraseTextField.returnKeyType = .done
//        passphraseTextField.delegate = self

        // Tweak mnemonic collection view appearance
        mnemonicCollectionView.backgroundColor = ._systemGray5

        // Setup password tableView
        passwordTableView.dataSource = self
        passwordTableViewCell.passphraseTextField.delegate = self

        // Bind import button action target
        importButton.addTarget(self, action: #selector(ImportWalletViewController.importButtonPressed(_:)), for: .touchUpInside)

        // Setup activity indicator
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.stopAnimating()

        viewModel.delegate = self
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        scrollViewContentLayoutGuideHeight.constant = view.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom
        scrollViewContentLayoutGuideHeight.isActive = true

        scrollViewContentLayoutGuideBottomToDoneButtonBottom.constant = view.safeAreaInsets.bottom > 0 ? 0 : 26
    }

}

extension ImportWalletViewController {

    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @objc private func importButtonPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Error", message: "", preferredStyle: .alert)
        let okAction = UIAlertAction(title: L10n.Common.Button.ok, style: .default, handler: nil)
        alertController.addAction(okAction)

        do {
            let mnemonic = viewModel.mnemonic
            let passphrase = passwordTableViewCell.passphraseTextField.text ?? ""
            let wallet = Wallet(mnemonic: mnemonic, passphrase: passphrase)
            _ = try HDWallet(mnemonic: mnemonic, passphrase: passphrase, network: .mainnet(.ether))
            WalletService.default.append(wallet: wallet)
            dismiss(animated: true, completion: nil)
        } catch HDWalletError.invalidMnemonic {
            alertController.message = "Inavlid Mnemonic.\n Please try again"
            present(alertController, animated: true, completion: nil)
        } catch {
            alertController.message = "Import failed due to \(error.localizedDescription)"
            present(alertController, animated: true, completion: nil)
        }

    }

}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ImportWalletViewController: UIAdaptivePresentationControllerDelegate {

    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return traitCollection.horizontalSizeClass == .compact ? .fullScreen : .pageSheet
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }

}

// MARK: - UITextFieldDelegate
extension ImportWalletViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === passwordTableViewCell.passphraseTextField {
            textField.resignFirstResponder()
        }
        return false
    }
}

// MARK: - ImportMnemonicCollectionViewModelDelegate
extension ImportWalletViewController: ImportMnemonicCollectionViewModelDelegate {

    // Move focus from mnemonic last cell to password textField
    func importMnemonicCollectionViewModel(_ viewModel: ImportMnemonicCollectionViewModel, lastTextFieldReturn textField: UITextField) {
        passwordTableViewCell.passphraseTextField.becomeFirstResponder()
    }

}

// MARK: - UITableViewDataSource
extension ImportWalletViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = passwordTableViewCell
        cell.passphraseTextField.placeholder = "Password"
        return cell
    }

}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct ImportWalletViewController_Preview: PreviewProvider {

    static var previews: some View {
        let rootViewController = ImportWalletViewController()

        return Group {
            NavigationControllerRepresenable(rootViewController: rootViewController)
        }
    }

}
#endif
