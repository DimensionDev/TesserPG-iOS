//
//  MessageCardViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-7-19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

protocol MessageCardViewModelDelegate: class {
    func writeReply(to recipients: [KeyBridge], from sender: KeyBridge?)
}

final class MessageCardViewModel {

    private let disposeBag = DisposeBag()
    weak var delegate: MessageCardViewModelDelegate?

    // Input
    let messages = BehaviorRelay<[Message]>(value: [])
    var allowActions = BehaviorRelay<[Action]>(value: [.copy, .reply])
    var copyAction = PublishRelay<UIButton>()
    var replyAction = PublishRelay<UIButton>()
    var copyContentType = CopyContentType.rawMessage

    // Output
    private let _availableActions = BehaviorRelay<[Action]>(value: [])
    let availableActions: Driver<[Action]>

    init() {
        availableActions = Driver.combineLatest(allowActions.asDriver(), _availableActions.asDriver()) { allowActions, availableActions in
            return availableActions.filter { allowActions.contains($0) }
        }.asDriver()

        messages.asDriver()
            .drive(onNext: { [weak self] messages in
                // skip if not last
                guard let message = messages.last, let `self` = self else { return }

                // set available actions
                if ProfileService.default.containsKey(longIdentifier: message.senderKeyId) {
                    self._availableActions.accept([.copy, .reply])
                } else {
                    self._availableActions.accept([.copy])
                }
            })
            .disposed(by: disposeBag)

        // handler actions
        copyAction
            .observeOn(MainScheduler.asyncInstance)
            .do(onNext: { sender in
                sender.setTitle(L10n.InterpretActionViewController.Action.Button.copied, for: .normal)
                let message = self.messages.value.last
                UIPasteboard.general.string = self.copyContentType == .rawMessage ? message?.rawMessage : message?.encryptedMessage
            })
            .debounce(1, scheduler: MainScheduler.asyncInstance)
            .delay(1, scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { sender in
                sender.setTitle(L10n.InterpretActionViewController.Action.Button.copyContent, for: .normal)
            })
            .disposed(by: disposeBag)

        replyAction
            .observeOn(MainScheduler.asyncInstance)
            .debounce(1, scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] sender in
                guard let message = self?.messages.value.last else {
                    return
                }

                let sender = message
                    .getRecipients()
                    .first(where: { recipient in
                        // select first recipient's key, which user has it's secret key, as sender key to reply
                        guard let key = recipient.getKey(), key.hasPublicKey, key.hasSecretKey else { return false }
                        return true
                    })
                    .flatMap { $0.getKey() }
                    .map { KeyBridge(contact: nil, key: $0, userID: $0.userID, longIdentifier: $0.longIdentifier) }

                let recipient = KeyBridge(contact: nil, key: nil, userID: message.senderKeyUserId, longIdentifier: message.senderKeyId)

                self?.delegate?.writeReply(to: [recipient], from: sender)
            })
            .disposed(by: disposeBag)
    }

}

extension MessageCardViewModel {

    enum Action {
        case copy
        case reply
    }

    enum CopyContentType {
        case rawMessage
        case armoredMessage
    }

}

final class MessageCardViewController: UIViewController {

    private let disposeBag = DisposeBag()
    let viewModel = MessageCardViewModel()

    lazy var messageCardTableViewController = MessageCardTableViewController()

    private lazy var bottomActionsView: UIStackView = {
        let stackView = UIStackView(frame: .zero)
        stackView.spacing = 15
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        return stackView
    }()

}

extension MessageCardViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ._systemBackground

        addChild(messageCardTableViewController)
        view.addSubview(messageCardTableViewController.view)
        messageCardTableViewController.didMove(toParent: self)

        bottomActionsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomActionsView)
        let bottomActionsViewBottomConstraint = bottomActionsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        bottomActionsViewBottomConstraint.priority = .defaultLow
        NSLayoutConstraint.activate([
            bottomActionsView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            bottomActionsView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            view.bottomAnchor.constraint(greaterThanOrEqualTo: bottomActionsView.bottomAnchor, constant: 16),
            bottomActionsViewBottomConstraint,
        ])

        // Combine view model
        viewModel.messages.asDriver()
            .drive(messageCardTableViewController.viewModel.messages)
            .disposed(by: disposeBag)
        viewModel.availableActions.asDriver()
            .drive(onNext: { [weak self] actions in
                self?.reloadBottomActionView(with: actions)
            })
            .disposed(by: disposeBag)
    }

}

extension MessageCardViewController {

    private func reloadBottomActionView(with actions: [MessageCardViewModel.Action]) {
        bottomActionsView.arrangedSubviews.forEach {
            bottomActionsView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        if actions.contains(.copy) {
            let copyButton = TCActionButton(frame: .zero)
            if #available(iOS 13, *) {
                copyButton.color = .secondarySystemBackground
                copyButton.setTitleColor(.label, for: .normal)
            } else {
                copyButton.color = .white
                copyButton.setTitleColor(.black, for: .normal)
            }
            copyButton.setTitle(L10n.InterpretActionViewController.Action.Button.copyContent, for: .normal)
            copyButton.addTarget(self, action: #selector(MessageCardViewController.composeButtonPressed(_:)), for: .touchUpInside)

            bottomActionsView.addArrangedSubview(copyButton)
        }

        if actions.contains(.reply) {
            let replyButton = TCActionButton(frame: .zero)
            replyButton.color = .systemBlue
            replyButton.setTitleColor(.white, for: .normal)
            replyButton.setTitle(L10n.InterpretActionViewController.Action.Button.writeReply, for: .normal)
            replyButton.addTarget(self, action: #selector(MessageCardViewController.replyButtonPressed(_:)), for: .touchUpInside)

            bottomActionsView.addArrangedSubview(replyButton)
        }

        bottomActionsView.setNeedsLayout()
        bottomActionsView.layoutIfNeeded()

        // add some spacing for table view bottom
        messageCardTableViewController.additionalSafeAreaInsets.bottom = bottomActionsView.frame.height + 15
    }

    @objc private func composeButtonPressed(_ sender: UIButton) {
        viewModel.copyAction.accept(sender)
    }

    @objc private func replyButtonPressed(_ sender: UIButton) {
        viewModel.replyAction.accept(sender)
    }

}
