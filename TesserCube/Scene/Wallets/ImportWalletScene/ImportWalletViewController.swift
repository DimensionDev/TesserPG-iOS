//
//  ImportWalletViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-8.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift

class ImportWalletViewController: TCBaseViewController {

    private let disposeBag = DisposeBag()

    private let scrollView = UIScrollView()
    private var scrollViewContentLayoutGuideHeight: NSLayoutConstraint!
    private var scrollViewContentLayoutGuideBottomToDoneButtonBottom: NSLayoutConstraint!

    let passphraseTextField = PassphraseTextField()
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

        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        // scrollView.backgroundColor = .viewBackgroundGray
        scrollView.preservesSuperviewLayoutMargins = true
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

        passphraseTextField.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(passphraseTextField)
        NSLayoutConstraint.activate([
            passphraseTextField.topAnchor.constraint(equalTo: mnemonicCollectionView.bottomAnchor, constant: 20),
            passphraseTextField.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            passphraseTextField.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            passphraseTextField.heightAnchor.constraint(equalToConstant: 44),
        ])

        // Layout import button
        importButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(importButton)
        scrollViewContentLayoutGuideBottomToDoneButtonBottom = scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: importButton.bottomAnchor, constant: 0)
        NSLayoutConstraint.activate([
            importButton.topAnchor.constraint(greaterThanOrEqualTo: passphraseTextField.bottomAnchor, constant: 20),
            importButton.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            importButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            importButton.heightAnchor.constraint(equalToConstant: 50),
            scrollViewContentLayoutGuideBottomToDoneButtonBottom
        ])

        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: importButton.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: importButton.centerYAnchor),
        ])

        //importButton.setTitle(L10n.ImportMemonicViewController.ImportButton.title, for: .normal)
        //importButton.addTarget(self, action: #selector(ImportMemonicViewController.importButtonPressed(_:)), for: .touchUpInside)

        passphraseTextField.isSecureTextEntry = true
        passphraseTextField.keyboardType = .asciiCapable
        passphraseTextField.autocorrectionType = .no
        passphraseTextField.autocapitalizationType = .none
        passphraseTextField.enablesReturnKeyAutomatically = true
        passphraseTextField.returnKeyType = .done
        passphraseTextField.delegate = self

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

    public override func viewLayoutMarginsDidChange() {
        super.viewLayoutMarginsDidChange()

        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: view.layoutMargins.left, height: 1))
        passphraseTextField.leftViewMode = .always
        passphraseTextField.leftView = paddingView
    }

}

extension ImportWalletViewController {

    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
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
        textField.resignFirstResponder()
        return false
    }
}

// MARK: - ImportMnemonicCollectionViewModelDelegate
extension ImportWalletViewController: ImportMnemonicCollectionViewModelDelegate {

    func importMnemonicCollectionViewModel(_ viewModel: ImportMnemonicCollectionViewModel, lastTextFieldReturn textField: UITextField) {
        passphraseTextField.becomeFirstResponder()
    }

}
