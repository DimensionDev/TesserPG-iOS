//
//  ImportKeyViewController.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/20.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit
import RxCocoa
import RxSwift

class ImportKeyViewController: TCBaseViewController {
    
    let disposeBag = DisposeBag()
    
    private lazy var contentScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delaysContentTouches = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    var contentScrollViewContentLayoutGuideHeight: NSLayoutConstraint!

    
    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(frame: .zero)
        stackView.spacing = 12
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        return stackView
    }()
    
    private lazy var fromPGPLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = FontFamily.SFProDisplay.regular.font(size: 17)
        if #available(iOS 13, *) {
            label.textColor = .secondaryLabel
        } else {
            label.textColor = Asset.promptLabel.color
        }
        label.textAlignment = .center
        label.text = L10n.ImportKeyController.Prompt.fromPGP
        return label
    }()

    private lazy var laterButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = FontFamily.SFProDisplay.medium.font(size: 17)
        if #available(iOS 13, *) {
            button.setTitleColor(.label, for: .normal)
        } else {
            button.setTitleColor(.black, for: .normal)
        }
        button.setTitle(L10n.ImportKeyController.Action.Button.maybeLater, for: .normal)
        button.titleLabel?.textAlignment = .center

        return button
    }()
    
    override func configUI() {
        super.configUI()

        navigationItem.largeTitleDisplayMode = .never
        title = L10n.MeViewController.Action.Button.importKey

        view.addSubview(contentScrollView)
        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            contentScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentScrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        contentScrollViewContentLayoutGuideHeight = contentScrollView.contentLayoutGuide.heightAnchor.constraint(greaterThanOrEqualToConstant: view.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom)

        contentScrollView.addSubview(laterButton)
        laterButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            laterButton.heightAnchor.constraint(equalToConstant: 50),
            laterButton.leadingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.leadingAnchor),
            laterButton.trailingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.trailingAnchor),
            laterButton.bottomAnchor.constraint(greaterThanOrEqualTo: contentScrollView.contentLayoutGuide.bottomAnchor)
        ])

        let imageView = UIImageView(image: Asset.sceneMeImportKey.image)
        contentScrollView.addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.top.equalTo(contentScrollView.contentLayoutGuide.snp.top).offset(41)
            maker.centerX.equalToSuperview()
            maker.width.height.equalTo(143)
        }
        imageView.contentMode = .scaleAspectFit

        contentScrollView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.bottom.equalTo(laterButton.snp.top).offset(-20)
            maker.width.equalToSuperview().offset(-32)
        }

        let pasteKeyButton = TCActionButton(frame: .zero)
        pasteKeyButton.color = Asset.sketchBlue.color
        pasteKeyButton.setTitleColor(.white, for: .normal)
        pasteKeyButton.setTitle(L10n.ImportKeyController.Action.Button.pastePrivateKey, for: .normal)

        contentStackView.addArrangedSubviews([fromPGPLabel, pasteKeyButton])
        contentStackView.setCustomSpacing(20, after: pasteKeyButton)

        pasteKeyButton.rx.tap.bind { [weak self] in
                Coordinator.main.present(scene: .pasteKey(needPassphrase: true), from: self)
            }
            .disposed(by: disposeBag)

        laterButton.rx.tap.bind { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        contentScrollViewContentLayoutGuideHeight.constant = view.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom
        contentScrollViewContentLayoutGuideHeight.isActive = true
    }

}
