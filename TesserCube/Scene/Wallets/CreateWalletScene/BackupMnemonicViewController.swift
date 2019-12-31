//
//  BackupMnemonicViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-6.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class BackupMnemonicViewController: TCBaseViewController {

    private let walletCardTableView: UITableView = {
        let tableView = UITableView()
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        tableView.register(WalletCardTableViewCell.self, forCellReuseIdentifier: String(describing: WalletCardTableViewCell.self))
        tableView.clipsToBounds = false
        return tableView
    }()

    var viewModel: BackupMnemonicCollectionViewModel!
    lazy var mnemonicCollectionView: MnemonicCollectionView = {
        let collectionView = MnemonicCollectionView(viewModel: viewModel)
        viewModel.collectionView = collectionView
        return collectionView
    }()

    private let middleHintLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProDisplay.regular.font(size: 17.0)
        label.textColor = ._secondaryLabel
        label.text = "Keep the 12 words carefully.\nWrite on paper. Do not take screenshot.\nThis is the only way to recover your key, if lost."
        label.numberOfLines = 3
        label.textAlignment = .center
        return label
    }()

    private let nextButton: TCActionButton = {
        let button = TCActionButton()
        button.color = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Next Step", for: .normal)
        return button
    }()
    private let skipBackupButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(._label, for: .normal)
        button.setTitleColor(.systemBlue, for: .highlighted)
        button.setTitle("Maybe Later", for: .normal)
        return button
    }()

    override func configUI() {
        super.configUI()

        title = "New Wallet Created"
        navigationItem.hidesBackButton = true

        let shouldAddCard = view.height > 700

        if shouldAddCard {
            // Layout wallet card tableView
            walletCardTableView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(walletCardTableView)
            NSLayoutConstraint.activate([
                walletCardTableView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 24),
                walletCardTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                walletCardTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                walletCardTableView.heightAnchor.constraint(equalToConstant: 122 + WalletCardTableViewCell.cardVerticalMargin * 2)
            ])
        }

        // Layout mnemonic collection view
        let mnemonicCollectionViewTopConstraint: NSLayoutConstraint
        if shouldAddCard {
            mnemonicCollectionViewTopConstraint = mnemonicCollectionView.topAnchor.constraint(equalTo: walletCardTableView.bottomAnchor, constant: 24)
        } else {
            mnemonicCollectionViewTopConstraint = mnemonicCollectionView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 24)
        }
        mnemonicCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mnemonicCollectionView)
        NSLayoutConstraint.activate([
            mnemonicCollectionViewTopConstraint,
            mnemonicCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            view.trailingAnchor.constraint(equalTo: mnemonicCollectionView.trailingAnchor, constant: 16),
            mnemonicCollectionView.heightAnchor.constraint(equalToConstant: MnemonicCollectionView.height)
        ])
        mnemonicCollectionView.setContentHuggingPriority(.defaultLow, for: .vertical)
        mnemonicCollectionView.setContentCompressionResistancePriority(.required, for: .vertical)

        // Layout Button
        skipBackupButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(skipBackupButton)
        let skipBackupButtonBottomLayoutConstraint = view.bottomAnchor.constraint(greaterThanOrEqualTo: skipBackupButton.bottomAnchor, constant: 16)
        let skipBackupButtonBottomSafeAreaLayoutConstraint = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: skipBackupButton.bottomAnchor)
        skipBackupButtonBottomSafeAreaLayoutConstraint.priority = .defaultLow
        NSLayoutConstraint.activate([
            skipBackupButtonBottomLayoutConstraint,
            skipBackupButtonBottomSafeAreaLayoutConstraint,
            skipBackupButton.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            skipBackupButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            skipBackupButton.heightAnchor.constraint(equalToConstant: 50),
        ])

        middleHintLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(middleHintLabel)
        NSLayoutConstraint.activate([
            middleHintLabel.topAnchor.constraint(equalTo: mnemonicCollectionView.bottomAnchor, constant: 20),
            middleHintLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            middleHintLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])

        nextButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nextButton)
        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            nextButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            nextButton.heightAnchor.constraint(equalToConstant: 50),
            skipBackupButton.topAnchor.constraint(equalTo: nextButton.bottomAnchor, constant: 20),
        ])

        // Setup wallet card tableView
        walletCardTableView.dataSource = self
        walletCardTableView.delegate = self
        walletCardTableView.reloadData()
        
        // Bind button action
        nextButton.addTarget(self, action: #selector(BackupMnemonicViewController.nextButtonPressed(_:)), for: .touchUpInside)
        skipBackupButton.addTarget(self, action: #selector(BackupMnemonicViewController.skipBackupButtonPressed(_:)), for: .touchUpInside)
    }

}

extension BackupMnemonicViewController {

    @objc private func nextButtonPressed(_ sender: UIButton) {
        let viewModel = ConfirmMnemonicCollectionViewModel(mnemonic: self.viewModel.wallet.mnemonic)
        Coordinator.main.present(scene: .confirmMnemonic(viewModel: viewModel), from: self, transition: .detail, completion: nil)
    }

    @objc private func skipBackupButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

}

// MARK: - UIAdaptivePresentationControllerDelegate
extension BackupMnemonicViewController: UIAdaptivePresentationControllerDelegate {

    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .overCurrentContext
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }

}

// MARK: - UITableViewDataSource
extension BackupMnemonicViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        guard tableView === walletCardTableView else {
            return 0
        }

        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard tableView === walletCardTableView else {
            return 0
        }

        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: WalletCardTableViewCell.self), for: indexPath) as! WalletCardTableViewCell

        guard let model = try? WalletModel(wallet: viewModel.wallet) else {
            return cell
        }
        WalletsViewModel.configure(cell: cell, with: model)
        
        return cell
    }

}

extension BackupMnemonicViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.bounds.height
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI
import DMS_HDWallet_Cocoa

@available(iOS 13.0, *)
struct MnemonicViewController_Previews: PreviewProvider {

    static var previews: some View {
        let rootViewController = BackupMnemonicViewController()
        let mnemonic = Mnemonic.create()
        let wallet = Wallet(mnemonic: mnemonic, passphrase: "")
        rootViewController.viewModel = BackupMnemonicCollectionViewModel(wallet: wallet)
        return Group {
            NavigationControllerRepresenable(rootViewController: rootViewController)
                .environment(\.colorScheme, .light)
            NavigationControllerRepresenable(rootViewController: rootViewController)
                .environment(\.colorScheme, .dark)
            NavigationControllerRepresenable(rootViewController: rootViewController)
                .environment(\.colorScheme, .light)
                .previewDevice(PreviewDevice(stringLiteral: "iPhone SE"))
            NavigationControllerRepresenable(rootViewController: rootViewController)
                .environment(\.colorScheme, .light)
                .previewDevice(PreviewDevice(stringLiteral: "iPhone 8"))
            NavigationControllerRepresenable(rootViewController: rootViewController)
                .environment(\.colorScheme, .light)
                .previewDevice(PreviewDevice(stringLiteral: "iPhone 8 Plus"))
            NavigationControllerRepresenable(rootViewController: rootViewController)
                .environment(\.colorScheme, .light)
                .previewDevice(PreviewDevice(stringLiteral: "iPhone X"))
            NavigationControllerRepresenable(rootViewController: rootViewController)
                .environment(\.colorScheme, .light)
                .previewDevice(PreviewDevice(stringLiteral: "iPhone XR"))
        }
    }

}

#endif
   
