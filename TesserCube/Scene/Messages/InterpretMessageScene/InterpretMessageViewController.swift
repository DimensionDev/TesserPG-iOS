//
//  InterpretMessageViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-3-30.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import DMSOpenPGP
import RxSwift
import RxCocoa
import UITextView_Placeholder

final class InterpretMessageViewController: TCBaseViewController {

    let disposeBag = DisposeBag()
    let viewModel = InterpretMessageViewModel()
    
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        if #available(iOS 13, *) {
            scrollView.backgroundColor = .systemBackground
        } else {
            scrollView.backgroundColor = Asset.sceneBackground.color
        }
        return scrollView
    }()
    
    let messageTextView: UITextView = {
        let textView = UITextView()
        if #available(iOS 13, *) {
            textView.placeholderColor = .placeholderText
        } else {
            textView.placeholderColor = Asset.lightTextGrey.color
        }
        textView.placeholder = L10n.ComposeMessageViewController.TextView.Message.placeholder
        textView.isScrollEnabled = false
        textView.font = FontFamily.SFProText.regular.font(size: 15)
        textView.textContainerInset.left = RecipientContactPickerView.leadingMargin - 4
        textView.backgroundColor = .clear
        return textView
    }()
    
    override func configUI() {
        super.configUI()
        
        title = L10n.InterpretMessageViewController.title
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: L10n.Common.Button.cancel, style: .plain, target: self, action: #selector(InterpretMessageViewController.cancelBarButtonItemPressed(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: L10n.ComposeMessageViewController.BarButtonItem.finish, style: .done, target: self, action: #selector(InterpretMessageViewController.doneBarButtonItemPressed(_:)))
        
        let margin = UIApplication.shared.keyWindow.flatMap { $0.safeAreaInsets.top + $0.safeAreaInsets.bottom } ?? 0
        let barHeight = navigationController?.navigationBar.bounds.height ?? 0
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0),
            scrollView.contentLayoutGuide.heightAnchor.constraint(greaterThanOrEqualToConstant: view.bounds.height - margin - barHeight),
        ])
       
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(messageTextView)
        NSLayoutConstraint.activate([
            messageTextView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            messageTextView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            messageTextView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            messageTextView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
        ])
        
        messageTextView.rx.text.orEmpty.asDriver()
            .drive(viewModel.message)
            .disposed(by: disposeBag)
    }
    
}

private extension InterpretMessageViewController {
    
    @objc func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func doneBarButtonItemPressed(_ sender: UIBarButtonItem) {
        viewModel.interpretMessage()
            .subscribeOn(ConcurrentDispatchQueueScheduler.init(qos: .userInitiated))
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] decrptedMessage in
                self?.dismiss(animated: true, completion: nil)
            }, onError: { [weak self] error in
                guard let `self` = self else { return }
                let message = error.localizedDescription
                self.showSimpleAlert(title: L10n.Common.Alert.error, message: message)
            })
            .disposed(by: disposeBag)
    }
    
}

extension InterpretMessageViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if hasValidKeyInPasteboard(), messageTextView.text.isEmpty {
            messageTextView.text = UIPasteboard.general.string
        }
    }
}

extension InterpretMessageViewController {
    
    private func hasValidKeyInPasteboard() -> Bool {
        if UIPasteboard.general.hasStrings, let pasteString = UIPasteboard.general.string,
        DMSPGPDecryptor.verify(armoredMessage: pasteString) {   // FIXME: veriy function not work as expected
            return true
        }
        return false
    }
    
}
