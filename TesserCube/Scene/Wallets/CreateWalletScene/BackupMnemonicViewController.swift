//
//  BackupMnemonicViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-6.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class BackupMnemonicViewController: TCBaseViewController {

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

    var viewModel: BackupMnemonicCollectionViewModel!
    lazy var mnemonicCollectionView: MnemonicCollectionView = {
        let collectionView = MnemonicCollectionView(viewModel: viewModel)
        viewModel.collectionView = collectionView
        return collectionView
    }()

    override func configUI() {
        super.configUI()

        title = "New Wallet Created"
        navigationItem.hidesBackButton = true

        // Layout wallet card cell
        let walletCardCell = UIView()
        walletCardCell.backgroundColor = .systemPurple
        walletCardCell.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(walletCardCell)
        NSLayoutConstraint.activate([
            walletCardCell.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 24),
            walletCardCell.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            walletCardCell.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            walletCardCell.heightAnchor.constraint(equalToConstant: 106)
        ])
        walletCardCell.setContentHuggingPriority(.defaultHigh, for: .vertical)

        // Layout mnemonic collection view
        mnemonicCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mnemonicCollectionView)
        NSLayoutConstraint.activate([
            mnemonicCollectionView.topAnchor.constraint(equalTo: walletCardCell.bottomAnchor, constant: 24),
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

        nextButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nextButton)
        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            nextButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            nextButton.heightAnchor.constraint(equalToConstant: 50),
            skipBackupButton.topAnchor.constraint(equalTo: nextButton.bottomAnchor, constant: 20),
        ])

        // Bind button action
        nextButton.addTarget(self, action: #selector(BackupMnemonicViewController.nextButtonPressed(_:)), for: .touchUpInside)
        skipBackupButton.addTarget(self, action: #selector(BackupMnemonicViewController.skipBackupButtonPressed(_:)), for: .touchUpInside)
    }

}

extension BackupMnemonicViewController {

    @objc private func nextButtonPressed(_ sender: UIButton) {
        let viewModel = ConfirmMnemonicCollectionViewModel(mnemonic: self.viewModel.mnemonic)
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

#if canImport(SwiftUI) && DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct MnemonicViewController_Previews: PreviewProvider {

    static var previews: some View {
        NavigationControllerRepresenable(rootViewController: BackupMnemonicViewController())
    }

}

#endif
