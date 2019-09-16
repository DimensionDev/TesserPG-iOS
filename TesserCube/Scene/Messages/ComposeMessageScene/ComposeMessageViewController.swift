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
import ConsolePrint

final class ComposeMessageViewController: TCBaseViewController {
    
    var preselectedContacts = [Contact]()

    let disposeBag = DisposeBag()
    let viewModel = ComposeMessageViewModel()

    let toContactPickerCellView = RecipientContactPickerView()
    let fromContactPickerCellView = SenderContactPickerView()
    let messageTextView: UITextView = {
        let textView = UITextView()
        textView.placeholderColor = ._secondaryLabel
        textView.placeholder = L10n.ComposeMessageViewController.TextView.Message.placeholder
        textView.isScrollEnabled = false
        textView.font = FontFamily.SFProText.regular.font(size: 15)
        textView.textContainerInset.left = RecipientContactPickerView.leadingMargin - 4
        textView.backgroundColor = .clear
        return textView
    }()

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive

        if #available(iOS 13, *) {
            scrollView.backgroundColor = .systemBackground
        } else {
            scrollView.backgroundColor = ._systemBackground
        }
        return scrollView
    }()

    lazy var cancelBarButtonItem: UIBarButtonItem = UIBarButtonItem(title: L10n.Common.Button.cancel, style: .plain, target: self, action: #selector(ComposeMessageViewController.cancelBarButtonItemPressed(_:)))

    // for callee (a.k.a InterpretActionViewController)
    var composedMessage: Message?

    override func configUI() {
        super.configUI()
        
        // MARK: - setup layout
        title = L10n.ComposeMessageViewController.title
        navigationItem.leftBarButtonItem = cancelBarButtonItem
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: L10n.ComposeMessageViewController.BarButtonItem.finish, style: .done, target: self, action: #selector(ComposeMessageViewController.doneBarButtonItemPressed(_:)))

        #if !TARGET_IS_EXTENSION
        let margin = UIApplication.shared.keyWindow.flatMap { $0.safeAreaInsets.top + $0.safeAreaInsets.bottom } ?? 0
        let barHeight = navigationController?.navigationBar.bounds.height ?? 0
        #else
        let margin = CGFloat.zero
        let barHeight = CGFloat.zero
        #endif

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
            messageTextView.topAnchor.constraint(equalTo: fromContactPickerCellView.bottomAnchor, constant: 5),
            messageTextView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            messageTextView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            messageTextView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
        ])

        toContactPickerCellView.titleLabel.text = L10n.ComposeMessageViewController.RecipientContactPickerView.TitleLabel.Text.to
        toContactPickerCellView.contactPickerTagCollectionViewCellDelegate = self
        toContactPickerCellView.pickContactsDelegate = self

        // MARK: - combine view model

        // combine toContactPickerCellView after view did appear to fix layout crash issue
        viewModel.viewDidAppear.asObservable()
            .filter { $0 }
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                // restore message recipients (recompose / writeReply)
                if let message = self.viewModel.message.value {
                    let keyBridges = message.getRecipients().map { messageRecipient -> KeyBridge in
                        let key = messageRecipient.getKey()
                        let contacts = Contact.getOwnerContacts(longIdentifier: messageRecipient.keyId)
                        let contact = contacts.count == 1 ? contacts.first : nil
                        return KeyBridge(contact: contact, key: key, userID: messageRecipient.keyUserId, longIdentifier: messageRecipient.keyId)
                    }
                    self.viewModel.keyBridges.accept(keyBridges)
                }

                // bind data
                self.viewModel.keyBridges.asDriver()
                    .drive(self.toContactPickerCellView.viewModel.tags)
                    .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)

        fromContactPickerCellView.titleLabel.text = L10n.ComposeMessageViewController.SenderContactPickerView.TitleLabel.Text.from

        // combine message text
        messageTextView.rx.text.orEmpty.asDriver()
            .drive(viewModel.rawMessage)
            .disposed(by: disposeBag)

        // restore message sender (recompose / writeReply)
        if let message = viewModel.message.value {
            if message.senderKeyId.isEmpty {
                fromContactPickerCellView.viewModel.selectedKey.accept(nil)
                let lastIndex = fromContactPickerCellView.viewModel.keys.value.count
                fromContactPickerCellView.senderPickerView.selectRow(lastIndex, inComponent: 0, animated: false)
            } else {
                let senderKey = fromContactPickerCellView.viewModel.keys.value.first(where: { key in
                    key.longIdentifier == message.senderKeyId
                })

                let index = fromContactPickerCellView.viewModel.keys.value.firstIndex(where: {
                    consolePrint($0.longIdentifier == senderKey?.longIdentifier)
                    return $0.longIdentifier == senderKey?.longIdentifier
                })
                if let senderKey = senderKey, let index = index {
                    fromContactPickerCellView.viewModel.selectedKey.accept(senderKey)
                    fromContactPickerCellView.senderPickerView.selectRow(index, inComponent: 0, animated: false)
                } else {
                    // Select [None] when signer key is user's key
                    let lastIndex = fromContactPickerCellView.viewModel.keys.value.count
                    fromContactPickerCellView.viewModel.selectedKey.accept(nil)
                    fromContactPickerCellView.senderPickerView.selectRow(lastIndex, inComponent: 0, animated: false)
                }
            }

            // combine input message
            self.messageTextView.text = message.rawMessage
        }
    }

}

extension ComposeMessageViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.viewDidAppear.accept(true)
    }

    // use dismiss proxy for app extension post CompleteRequest safe
    private func dismiss() {
        // Post notification in App Extension & App. Due to in-app open URL not trigger Swift condition flag (TARGET_IS_EXTENSION)
        let userInfo = ["message": composedMessage]
        NotificationCenter.default.post(name: .messageComposeComplete, object: self, userInfo: userInfo as [AnyHashable : Any])

        dismiss(animated: true, completion: nil)
    }

}

private extension ComposeMessageViewController {

    /// Alert user save draft when re-compose or compose message
    /// Alert user update draft or discard change when edit draft
    /// Directly dismiss when nothing changed
    @objc func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        let rawMessage = viewModel.rawMessage.value.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = toContactPickerCellView.viewModel.tags.value
        let senderKey = fromContactPickerCellView.viewModel.selectedKey.value
        let recipientKeys = tags.compactMap { $0.key }

        guard !rawMessage.isEmpty else {
            self.dismiss()
            return
        }

        let isMessageChanged: Bool = {
            guard let message = viewModel.message.value else {
                return true
            }
            if message.senderKeyId == senderKey?.longIdentifier,
            message.senderKeyUserId == senderKey?.userID,
            Set(message.getRecipients().map { $0.keyId }) == Set(recipientKeys.map { $0.longIdentifier }),
            message.rawMessage == rawMessage {
                return false
            } else {
                return true
            }
        }()

        guard isMessageChanged else {
            self.dismiss()
            return
        }

        let saveDraftAlertController: UIAlertController = {
            let alertController = UIAlertController(title: L10n.ComposeMessageViewController.Alert.Title.saveDraft, message: nil, preferredStyle: .actionSheet)

            let discardAction = UIAlertAction(title: L10n.Common.Button.discard, style: .destructive, handler: { [weak self] _ in
                self?.self.dismiss()
            })
            alertController.addAction(discardAction)
            let saveActionTitle = self.viewModel.message.value?.isDraft ?? false ? L10n.ComposeMessageViewController.Alert.Action.updateDraft : L10n.ComposeMessageViewController.Alert.Action.saveDraft
            let saveAction = UIAlertAction(title: saveActionTitle, style: .default, handler: { [weak self] _ in
                guard let `self` = self else { return }
                if var message = self.viewModel.message.value, message.isDraft {
                    // TODO: handle error if throw
                    do {
                        try message.updateDraftMessage(senderKeyID: senderKey?.longIdentifier ?? "", senderKeyUserID: senderKey?.userID ?? "", rawMessage: rawMessage, recipients: recipientKeys)
                    } catch {
                        consolePrint(error.localizedDescription)
                    }
                } else {
                    // Create draft message if not edit draft
                    var message = Message(id: nil, senderKeyId: senderKey?.longIdentifier ?? "", senderKeyUserId: senderKey?.userID ?? "", composedAt: Date(), interpretedAt: nil, isDraft: true, rawMessage: rawMessage, encryptedMessage: "")
                    // TODO: handle error if throw
                    do {
                        try ProfileService.default.addMessage(&message, recipientKeys: recipientKeys)
                    } catch {
                        consolePrint(error.localizedDescription)
                    }
                }

                self.self.dismiss()
            })
            alertController.addAction(saveAction)
            let cancelAction = UIAlertAction(title: L10n.Common.Button.cancel, style: .cancel, handler: { _ in
                // Do nothing
            })
            alertController.addAction(cancelAction)
            return alertController
        }()

        if let presenter = saveDraftAlertController.popoverPresentationController {
            presenter.barButtonItem = sender
        }

        present(saveDraftAlertController, animated: true, completion: nil)
    }

    @objc func doneBarButtonItemPressed(_ sender: UIBarButtonItem) {
        let rawMessage = viewModel.rawMessage.value.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = toContactPickerCellView.viewModel.tags.value
        let senderKey = fromContactPickerCellView.viewModel.selectedKey.value
        let recipientKeys = tags.compactMap { $0.key }

        let invalidKeys = recipientKeys.filter { $0.keyRing.publicKeyRing.primaryEncryptionKey == nil }

        if tags.contains(where: { $0.contact == nil }) {
            let alertController = UIAlertController(title: L10n.ComposeMessageViewController.Alert.Title.skipInvalidResipients, message: nil, preferredStyle: .actionSheet)
            let finishAction = UIAlertAction(title: L10n.ComposeMessageViewController.Alert.Message.skipAndFinish, style: .destructive) { [weak self] _ in
                self?.doComposeMessage(rawMessage, to: recipientKeys, from: senderKey)
            }
            let cancelAction = UIAlertAction(title: L10n.Common.Button.cancel, style: .cancel, handler: nil)
            alertController.addAction(finishAction)
            alertController.addAction(cancelAction)

            if let presenter = alertController.popoverPresentationController {
                presenter.barButtonItem = sender
                presenter.permittedArrowDirections = []
            }

            present(alertController, animated: true, completion: nil)
        } else if !invalidKeys.isEmpty {
            let fingerprints = invalidKeys.map { $0.fingerprint }.joined(separator: ", ")

            let alertController = UIAlertController(title: L10n.ComposeMessageViewController.Alert.Title.missingEncryptionKey, message: L10n.ComposeMessageViewController.Alert.Message.missingEncryptionKey(fingerprints), preferredStyle: .alert)
            let okAction = UIAlertAction(title: L10n.Common.Button.ok, style: .default, handler: nil)
            alertController.addAction(okAction)

            present(alertController, animated: true, completion: nil)

        } else {
            doComposeMessage(rawMessage, to: recipientKeys, from: senderKey)
        }
    }

    // Note: Create new message whatever compose or re-compose except for draft.
    private func doComposeMessage(_ rawMessage: String, to recipients: [TCKey], from sender: TCKey?, password: String? = nil) {
        ComposeMessageViewModel.composeMessage(rawMessage, to: recipients, from: sender, password: password)
            .subscribeOn(ConcurrentDispatchQueueScheduler.init(qos: .userInitiated))
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] armored in
                guard let `self` = self else { return }
                if var message = self.viewModel.message.value, message.isDraft {
                    // TODO: handle error if throw
                    do {
                        try message.updateDraftMessage(senderKeyID: sender?.longIdentifier ?? "", senderKeyUserID: sender?.userID ?? "", rawMessage: rawMessage, recipients: recipients, isDraft: false, armoredMessage: armored)
                    } catch {
                        consolePrint(error.localizedDescription)
                    }
                } else {
                    var message = Message(id: nil, senderKeyId: sender?.longIdentifier ?? "", senderKeyUserId: sender?.userID ?? "", composedAt: Date(), interpretedAt: nil, isDraft: false, rawMessage: rawMessage, encryptedMessage: armored)
                    // TODO: handle error if throw
                    do {
                        self.composedMessage = try ProfileService.default.addMessage(&message, recipientKeys: recipients)
                    } catch {
                        consolePrint(error.localizedDescription)
                    }
                }

                self.dismiss()

                }, onError: { [weak self] error in
                    guard let `self` = self else { return }
                    let message = (error as? TCError)?.errorDescription ?? error.localizedDescription
                    self.showSimpleAlert(title: L10n.Common.Alert.error, message: message)
            })
            .disposed(by: self.disposeBag)
    }

}

// MARK: - PickContactsDelegate
extension ComposeMessageViewController: PickContactsDelegate {

    func contactsListViewController(_ controller: ContactsListViewController, didSelect contacts: [Contact]) {
        let selectKeyBridges = contacts
            .compactMap { contact -> [KeyBridge]? in
                let keys = contact.getKeys()
                guard !keys.isEmpty else { return nil }
                return keys.map { KeyBridge(contact: contact, key: $0) }
            }
            .flatMap { $0 }

        // unique keybridge by longIdentifier
        var keyBridges = viewModel.keyBridges.value
        let newKeybridges = selectKeyBridges.filter { selectkeyBridge in
            !keyBridges.contains(where: { selectkeyBridge.longIdentifier == $0.longIdentifier })
        }
        keyBridges.append(contentsOf: newKeybridges)
        viewModel.keyBridges.accept(keyBridges)
    }

}

// MARK: - ContactPickerTagCollectionViewCellDelegate
extension ComposeMessageViewController: ContactPickerTagCollectionViewCellDelegate {

    func contactPickerTagCollectionViewCell(_ cell: ContactPickerTagCollectionViewCell, didDeleteBackward: Void) {
        guard let indexPath = toContactPickerCellView.contactCollectionView.indexPath(for: cell) else {
            assertionFailure()
            return
        }

        var keyBridges = self.viewModel.keyBridges.value
        keyBridges.remove(at: indexPath.item)
        self.viewModel.keyBridges.accept(keyBridges)
    }

}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ComposeMessageViewController: UIAdaptivePresentationControllerDelegate {

    @available(iOS 13.0, *)
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        let rawMessage = viewModel.rawMessage.value.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = toContactPickerCellView.viewModel.tags.value
        let senderKey = fromContactPickerCellView.viewModel.selectedKey.value
        let recipientKeys = tags.compactMap { $0.key }

        guard !rawMessage.isEmpty else {
            return true
        }

        let isMessageChanged: Bool = {
            guard let message = viewModel.message.value else {
                return true
            }
            if message.senderKeyId == senderKey?.longIdentifier,
            message.senderKeyUserId == senderKey?.userID,
            Set(message.getRecipients().map { $0.keyId }) == Set(recipientKeys.map { $0.longIdentifier }),
            message.rawMessage == rawMessage {
                return false
            } else {
                return true
            }
        }()

        return !isMessageChanged
    }

    @available(iOS 13.0, *)
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        cancelBarButtonItemPressed(cancelBarButtonItem)
    }

}
