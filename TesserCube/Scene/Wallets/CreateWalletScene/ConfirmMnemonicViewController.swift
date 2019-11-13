//
//  ConfirmMnemonicViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-8.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift

class ConfirmMnemonicViewController: TCBaseViewController {

    private let disposeBag = DisposeBag()

    private let scrollView = UIScrollView()
    private var scrollViewContentLayoutGuideHeight: NSLayoutConstraint!
    private var scrollViewContentLayoutGuideBottomToDoneButtonBottom: NSLayoutConstraint!

    private let topHintLabel = UILabel()
    private let doneButton: TCActionButton = {
        let button = TCActionButton()
        button.color = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.setTitle(L10n.Common.Button.done, for: .normal)
        return button
    }()

    var viewModel: ConfirmMnemonicCollectionViewModel!
    private lazy var mnemonicCollectionView: MnemonicCollectionView! = {
        let collectionView = MnemonicCollectionView(viewModel: viewModel)
        viewModel.upperSelectedMnemonicCollectionView = collectionView
        return collectionView
    }()
    private lazy var confirmMnemonicCollectionView: MnemonicCollectionView! = {
        let collectionView = MnemonicCollectionView(viewModel: viewModel)
        viewModel.lowerSelectMnemonicCollectionView = collectionView
        return collectionView
    }()

    override func configUI() {
        super.configUI()

        title = "Confirm Backup"

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

        scrollView.keyboardDismissMode = .interactive
        scrollView.preservesSuperviewLayoutMargins = true
        scrollViewContentLayoutGuideHeight = scrollView.contentLayoutGuide.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)

        // Layout hint label
        topHintLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(topHintLabel)
        NSLayoutConstraint.activate([
            topHintLabel.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            topHintLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            topHintLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
        ])
        topHintLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)

        topHintLabel.textAlignment = .center
        topHintLabel.numberOfLines = 2
        topHintLabel.text = "Tap in correct order to confirm backup."

        // Layout mnemonic collection view
        mnemonicCollectionView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(mnemonicCollectionView)
        NSLayoutConstraint.activate([
           mnemonicCollectionView.topAnchor.constraint(equalTo: topHintLabel.bottomAnchor, constant: 24),
           mnemonicCollectionView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
           scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: mnemonicCollectionView.trailingAnchor, constant: 16),
           mnemonicCollectionView.heightAnchor.constraint(equalToConstant: MnemonicCollectionView.height),
       ])
        mnemonicCollectionView.setContentHuggingPriority(.defaultLow, for: .vertical)
        mnemonicCollectionView.setContentCompressionResistancePriority(.required, for: .vertical)

        confirmMnemonicCollectionView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(confirmMnemonicCollectionView)
        NSLayoutConstraint.activate([
           confirmMnemonicCollectionView.topAnchor.constraint(equalTo: mnemonicCollectionView.bottomAnchor, constant: 20),
           confirmMnemonicCollectionView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
           scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: confirmMnemonicCollectionView.trailingAnchor, constant: 16),
           confirmMnemonicCollectionView.heightAnchor.constraint(equalToConstant: MnemonicCollectionView.height)
       ])
        confirmMnemonicCollectionView.setContentHuggingPriority(.defaultLow, for: .vertical)
        confirmMnemonicCollectionView.setContentCompressionResistancePriority(.required, for: .vertical)

        // Layout done button
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(doneButton)
        scrollViewContentLayoutGuideBottomToDoneButtonBottom = scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: doneButton.bottomAnchor, constant: 0)
        NSLayoutConstraint.activate([
            doneButton.topAnchor.constraint(greaterThanOrEqualTo: confirmMnemonicCollectionView.bottomAnchor, constant: 20),
            doneButton.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            doneButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            doneButton.heightAnchor.constraint(equalToConstant: 50),
            scrollViewContentLayoutGuideBottomToDoneButtonBottom,
        ])

        // Bind button action
        doneButton.addTarget(self, action: #selector(ConfirmMnemonicViewController.doneButtonPressed(_:)), for: .touchUpInside)
        viewModel.isComplete.asDriver()
            .drive(doneButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        scrollViewContentLayoutGuideHeight.constant = view.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom
        scrollViewContentLayoutGuideHeight.isActive = true

        scrollViewContentLayoutGuideBottomToDoneButtonBottom.constant = view.safeAreaInsets.bottom > 0 ? 0 : 26
    }

}

extension ConfirmMnemonicViewController {

    @objc private func doneButtonPressed(_ sender: UIButton) {
        guard viewModel.isConfimed.value else {
            let alertController = UIAlertController(title: "Wrong order", message: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: L10n.Common.Button.ok, style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)

            return
        }

        dismiss(animated: true, completion: nil)
    }

}

#if canImport(SwiftUI) && DEBUG
import SwiftUI
import DMS_HDWallet_Cocoa

@available(iOS 13.0, *)
struct ConfirmMnemonicViewController_Preview: PreviewProvider {
    static var previews: some View {
        let rootViewController = ConfirmMnemonicViewController()
        let mnemonic = Mnemonic.create()
        rootViewController.viewModel = ConfirmMnemonicCollectionViewModel(mnemonic: mnemonic)

        return Group {
            NavigationControllerRepresenable(rootViewController: rootViewController)
                .environment(\.colorScheme, .light)
            NavigationControllerRepresenable(rootViewController: rootViewController)
            .environment(\.colorScheme, .dark)
        }
    }
}
#endif
