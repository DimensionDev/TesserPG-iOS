//
//  BrokenMessageViewController.swift
//  TesserCubeInterpretAction
//
//  Created by Cirno MainasuK on 2019-7-17.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

final class BrokenMessageViewController: UIViewController {

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

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0)
        ])

        let stackView = UIStackView(arrangedSubviews: [promptLabel, messageLabel])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill

        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 16),
            stackView.widthAnchor.constraint(equalTo: scrollView.contentLayoutGuide.widthAnchor),

            messageLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: 16),
        ])

    }

}
