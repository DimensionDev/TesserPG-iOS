//
//  BrokenMessageViewController.swift
//  TesserCubeInterpretAction
//
//  Created by Cirno MainasuK on 2019-7-17.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class BrokenMessageViewModel {
    // input
    let message = BehaviorRelay<String?>(value: nil)
}

final class BrokenMessageViewController: UIViewController {

    let disposeBag = DisposeBag()
    let viewModel = BrokenMessageViewModel()

    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = Asset.sceneBackground.color
        scrollView.contentInsetAdjustmentBehavior = .automatic
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()

    let promptLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = FontFamily.SFProDisplay.regular.font(size: 16)
        label.textAlignment = .center
        label.textColor = .black
        label.text = "The following text was passed in.\nHowever, it seems not to be a PGP message."
        return label
    }()

    let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = FontFamily.Menlo.regular.font(size: 14)
        label.text = ""
        return label
    }()

}

extension BrokenMessageViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        #if !TARGET_IS_EXTENSION
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: L10n.Common.Button.done, style: .done, target: self, action: #selector(BrokenMessageViewController.doneBarButtonPressed(_:)))
        #endif

        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
            scrollView.backgroundColor = .systemBackground
            promptLabel.textColor = .secondaryLabel
            messageLabel.textColor = .label
        }

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0),
        ])

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill

        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
        ])

        stackView.addArrangedSubview(promptLabel)
        stackView.addArrangedSubview(messageLabel)

        // Setup view model
        viewModel.message.asDriver()
            .map { $0 ?? "[empty]" }
            .drive(messageLabel.rx.text)
            .disposed(by: disposeBag)
    }
 
}

extension BrokenMessageViewController {

    @objc private func doneBarButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

}
