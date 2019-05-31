//
//  ComposeMessageViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-3-25.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import UITextView_Placeholder

//protocol ComposeMessageViewControllerDelegate: class {
//    // TODO: rename
//    func ComposeMessageViewController(_ controller: ComposeMessageViewController, didComposeMessage message: MessageModel)
//}

// TODO: add tap gesture to emit add contact view controller
final class ComposeMessageViewController: TCBaseViewController {

    let disposeBag = DisposeBag()
    var viewModel: ComposeMessageViewModel!

    let toContactPickerCellView = RecipientContactPickerView()
    let fromContactPickerCellView = SenderContactPickerView()
    let messageTextView: UITextView = {
        let textView = UITextView()
        textView.placeholderColor = Asset.lightTextGrey.color
        textView.placeholder = L10n.ComposeMessageViewController.TextView.Message.placeholder
        textView.isScrollEnabled = false
        textView.font = FontFamily.SFProText.regular.font(size: 15)
        textView.contentInset.left = RecipientContactPickerView.leadingMargin - 4
        textView.backgroundColor = .clear
        return textView
    }()

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        scrollView.backgroundColor = Asset.sceneBackground.color
        return scrollView
    }()

//    weak var delegate: ComposeMessageViewControllerDelegate?

    override func configUI() {
        super.configUI()

        title = L10n.ComposeMessageViewController.title
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: L10n.Common.Button.cancel, style: .plain, target: self, action: #selector(ComposeMessageViewController.cancelBarButtonItemPressed(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: L10n.ComposeMessageViewController.BarButtonItem.finish, style: .done, target: self, action: #selector(ComposeMessageViewController.doneBarButtonItemPressed(_:)))

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

        // To:
        toContactPickerCellView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(toContactPickerCellView)
        NSLayoutConstraint.activate([
            toContactPickerCellView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 4),
            toContactPickerCellView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            toContactPickerCellView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
        ])

        // From:
        fromContactPickerCellView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(fromContactPickerCellView)
        NSLayoutConstraint.activate([
            fromContactPickerCellView.topAnchor.constraint(equalTo: toContactPickerCellView.bottomAnchor),
            fromContactPickerCellView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            fromContactPickerCellView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
        ])

        NSLayoutConstraint.activate([
            toContactPickerCellView.titleLabel.widthAnchor.constraint(equalTo: fromContactPickerCellView.titleLabel.widthAnchor),
        ])

        // Message:
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(messageTextView)
        NSLayoutConstraint.activate([
            messageTextView.topAnchor.constraint(equalTo: fromContactPickerCellView.bottomAnchor),
            messageTextView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            messageTextView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            messageTextView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
        ])

        toContactPickerCellView.titleLabel.text = L10n.ComposeMessageViewController.RecipientContactPickerView.TitleLabel.Text.to
        toContactPickerCellView.pickContactsDelegate = self
        fromContactPickerCellView.delegate = self
        viewModel.recipients.asDriver().drive(toContactPickerCellView.viewModel.contacts).disposed(by: disposeBag)

        fromContactPickerCellView.titleLabel.text = L10n.ComposeMessageViewController.SenderContactPickerView.TitleLabel.Text.from

        messageTextView.rx.text.orEmpty.asDriver()
            .drive(viewModel.rawMessage)
            .disposed(by: disposeBag)
    }

}

private extension ComposeMessageViewController {

    @objc func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @objc func doneBarButtonItemPressed(_ sender: UIBarButtonItem) {
        let message = viewModel.rawMessage.value.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = toContactPickerCellView.viewModel.tags.value
        let recipientKeys = tags.compactMap { $0.key }

        guard let sender = fromContactPickerCellView.viewModel.selectedKey.value else {
            self.showAlert(title: "Error", message: L10n.ComposeMessageViewController.Alert.Message.invalidSender)
            return
        }

        viewModel.encryptedMessage(to: recipientKeys, from: sender)
            .subscribeOn(ConcurrentDispatchQueueScheduler.init(qos: .userInitiated))
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] armored in
                guard let `self` = self else { return }
                var compoedMessage = Message(id: nil, senderKeyId: sender.longIdentifier, composedAt: Date(), interpretedAt: nil, isDraft: false, rawMessage: message, encryptedMessage: armored)
                // TODO: handle error if throw
                try? ProfileService.default.addMessage(&compoedMessage, recipientKeys: recipientKeys)
//                let messageModel = MessageModel(recipients: tags, sender: sender, message: message, armoredMessage: armored, composeDate: Date(), interpretData: Date())
//                self.delegate?.ComposeMessageViewController(self, didComposeMessage: messageModel)
                self.dismiss(animated: true, completion: nil)

            }, onError: { [weak self] error in
                guard let `self` = self else { return }
                let message = (error as? ComposeMessageViewModel.Error)?.localizedDescription ?? error.localizedDescription
                self.showSimpleAlert(title: "Error", message: message)
            })
            .disposed(by: disposeBag)
    }

}

// MARK: - PickContactsDelegate
extension ComposeMessageViewController: PickContactsDelegate {

    func contactsListViewController(_ controller: ContactsListViewController, didSelect contacts: [Contact]) {
        var recipients = viewModel.recipients.value
        let newRecipients = contacts.filter { newContact in
            return !recipients.contains(where: { $0.id == newContact.id })
        }
        recipients.append(contentsOf: newRecipients)
        viewModel.recipients.accept(recipients)
    }

}

// MARK: - SenderContactPickerViewDelegate
extension ComposeMessageViewController: SenderContactPickerViewDelegate { }
