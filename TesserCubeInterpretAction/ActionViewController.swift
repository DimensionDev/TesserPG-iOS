//
//  ActionViewController.swift
//  TesserCubeInterpretAction
//
//  Created by Cirno MainasuK on 2019-7-16.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MobileCoreServices
import BouncyCastle_ObjC
import DMSOpenPGP

final class ActionViewModel: NSObject {

    private let disposeBag = DisposeBag()

    // Input
    var inputTexts: [String] = []

    // Output
    let armoredMessage = BehaviorRelay<String?>(value: nil)
    let message = BehaviorRelay<Message?>(value: nil)

    override init() {
        armoredMessage.asDriver()
            .delay(3)
            .flatMapLatest { message in
               return Driver.just(message.flatMap { try? ProfileService.default.decryptMessage($0) })
            }
            .drive(message)
            .disposed(by: disposeBag)
    }

}

extension ActionViewModel {

    func finalizeInput() {
        // Prevent user delete message in main app cause database not sync issue.
        let latestMessages = ProfileService.default.loadMessages()
        ProfileService.default.messages.accept(latestMessages)

        let message = inputTexts.first { DMSPGPDecryptor.verify(armoredMessage: $0) }
        armoredMessage.accept(message)
    }

}

// MARK: - UITableViewDataSource
extension ActionViewModel: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return message.value != nil ? 1 : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MessageCardCell.self), for: indexPath) as! MessageCardCell

        guard let messageModel = message.value else {
            return cell
        }

        cell.messageLabel.text = messageModel.rawMessage

        let senderInfoView = MessageContactInfoView()

        let senderMeta = PGPUserIDTranslator(userID: messageModel.senderKeyUserId)
        senderInfoView.nameLabel.text = MessagesViewModel.retrieveNameBy(longIdentifier: messageModel.senderKeyId, fallbackToMeta: senderMeta)
        senderInfoView.emailLabel.text = senderMeta.email.flatMap { "(\($0))"}
        senderInfoView.shortIDLabel.text = String(messageModel.senderKeyId.suffix(8))
        senderInfoView.shortIDLabel.textColor = Asset.shortIdBlue.color
        cell.signedByStackView.addArrangedSubview(senderInfoView)

        let recipeintsInfoViews = messageModel.getRecipients().map { recipient -> MessageContactInfoView in
            let infoView = MessageContactInfoView()
            let meta = PGPUserIDTranslator(userID: recipient.keyUserId)
            infoView.nameLabel.text = MessagesViewModel.retrieveNameBy(longIdentifier: recipient.keyId, fallbackToMeta: meta)
            infoView.emailLabel.text = meta.email.flatMap { "(\($0))"}
            infoView.shortIDLabel.text = String(recipient.keyId.suffix(8))
            return infoView
        }
        for view in recipeintsInfoViews {
            cell.recipeintsStackView.addArrangedSubview(view)
        }

        if recipeintsInfoViews.isEmpty {
            let infoView = MessageContactInfoView()
            infoView.nameLabel.text = L10n.Common.Label.nameNone
            cell.recipeintsStackView.addArrangedSubview(infoView)
        }

        var leftFooterText = ""
        var rightFooterText = ""
        if messageModel.isDraft {
            leftFooterText = messageModel.composedAt.flatMap { "\($0.timeAgoSinceNow)\(L10n.MessageCardCell.Label.composed)" } ?? ""
            rightFooterText = messageModel.interpretedAt.flatMap { "\($0.timeAgoSinceNow)\(L10n.MessageCardCell.Label.edited)" } ?? ""
        } else {
            if let composedDate = messageModel.composedAt {
                leftFooterText = "\(composedDate.timeAgoSinceNow)\(L10n.MessageCardCell.Label.composed)"
                if let interpretedDate = messageModel.interpretedAt {
                    rightFooterText = "\(interpretedDate.timeAgoSinceNow)\(L10n.MessageCardCell.Label.interpret)"
                }
            } else {
                leftFooterText = messageModel.interpretedAt.flatMap { "\($0.timeAgoSinceNow)\(L10n.MessageCardCell.Label.interpret)"} ?? ""
            }
        }
        cell.leftFooterLabel.text = leftFooterText
        cell.rightFooterLabel.text = rightFooterText
//
//        if let isExpand = messageExpandedDict[indexPath],
//            let maxNumberOfLines = messageMaxNumberOfLinesDict[indexPath] {
//            cell.messageLabel.numberOfLines = isExpand ? 0 : 4
//            cell.extraBackgroundViewHeightConstraint.constant = maxNumberOfLines > 4 ? 44 : 0
//            let title = isExpand ? L10n.MessageCardCell.Button.Expand.collapse : L10n.MessageCardCell.Button.Expand.expand(maxNumberOfLines)
//            cell.expandButton.setTitle(title, for: .normal)
//        } else {
//            cell.messageLabel.layoutIfNeeded()
//            let maxNumberOfLines = cell.messageLabel.maxNumberOfLines
//            messageExpandedDict[indexPath] = false
//            messageMaxNumberOfLinesDict[indexPath] = maxNumberOfLines
//            cell.messageLabel.numberOfLines = 4
//            cell.extraBackgroundViewHeightConstraint.constant = maxNumberOfLines > 4 ? 44 : 0
//            let title = L10n.MessageCardCell.Button.Expand.expand(maxNumberOfLines)
//            cell.expandButton.setTitle(title, for: .normal)
//        }

        cell.setNeedsLayout()
        cell.layoutIfNeeded()

        return cell
    }

}


final class ActionViewController: UIViewController {

    private let disposeBag = DisposeBag()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.alwaysBounceVertical = true
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 220
        tableView.register(MessageCardCell.self, forCellReuseIdentifier: String(describing: MessageCardCell.self))
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .interactive
        return tableView
    }()

    let viewModel = ActionViewModel()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        _init()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _init()
    }

    @IBAction func doneBarButtonItemPressed(_ sender: UIBarButtonItem) {
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }

    private func _init() {
        // Setup Bouncy Castle
        JavaSecuritySecurity.addProvider(with: OrgBouncycastleJceProviderBouncyCastleProvider())

    }

}

extension ActionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Asset.sceneBackground.color

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        tableView.dataSource = viewModel
        tableView.delegate = self

        viewModel.message.asDriver()
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        extractInputFromExtensionContext()
    }

}

extension ActionViewController {

    private func extractInputFromExtensionContext() {
        // check input text
        let providers = extensionContext
            .flatMap { $0.inputItems as? [NSExtensionItem] }
            .flatMap { items in return items.compactMap { $0.attachments }.flatMap { $0 } } ?? []

        guard !providers.isEmpty else {
            assertionFailure()
            return
        }

        for (i, provider) in providers.enumerated() {
            let typeIdentifier = kUTTypePlainText as String
            guard provider.hasItemConformingToTypeIdentifier(typeIdentifier) else { continue }

            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] text, error in
                guard let `self` = self else { return }
                guard error == nil else { return }
                guard let text = text as? String else { return }

                self.viewModel.inputTexts.append(text)

                if i == providers.count - 1 {
                    // notify viewModel done
                    DispatchQueue.main.async { [weak self] in
                        self?.viewModel.finalizeInput()
                    }
                }
            }
        }   // end for … in …
    }

}

// MARK: - UITableViewDelegate
extension ActionViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20 - MessageCardCell.cardVerticalMargin
    }

}
