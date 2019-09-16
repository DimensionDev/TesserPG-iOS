//
//  MessagesViewModel.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/22.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import DateToolsSwift

class MessagesViewModel: NSObject {

    @available(iOS 13.0, *)
    enum Section: CaseIterable {
        case main
    }

    var diffableDataSource: UITableViewDataSource!

    enum MessageType: CaseIterable {
        case timeline
        case savedDrafts

        var segmentedControlTitle: String {
            switch self {
            case .timeline: return L10n.MessagesViewController.SegmentedControl.timeline
            case .savedDrafts: return L10n.MessagesViewController.SegmentedControl.savedDrafts
            }
        }
    }

    let disposeBag = DisposeBag()

    // Input
    // all messages in database
    let _messages = BehaviorRelay<[Message]>(value: [])
    let searchText = BehaviorRelay(value: "")

    // UI cache for displaying message
    var messageExpandedDict: [IndexPath: Bool] = [:]
    var messageMaxNumberOfLinesDict: [IndexPath: Int] = [:]

    // For diffable datasource
    var messageExpandedIDDict: [Int64: Bool] = [:]
    var messageMaxNumberOfLinesIDDict: [Int64 : Int] = [:]

    // Output
    let segmentedControlItems = MessageType.allCases.map { $0.segmentedControlTitle }
    // messages should display
    let messages = BehaviorRelay<[Message]>(value: [])
    let selectedSegmentIndex = BehaviorRelay(value: 0)
    let selectedMessageType = BehaviorRelay<MessageType>(value: .timeline)
    let hasMessages: Driver<Bool>
    let isSearching: Driver<Bool>
    
    override init() {
        hasMessages = messages.asDriver().map { !$0.isEmpty }
        isSearching = searchText.asDriver().map { !$0.isEmpty }
        super.init()

        selectedSegmentIndex.asDriver()
            .filter { $0 >= 0 && $0 < self.segmentedControlItems.count }
            .map { MessageType.allCases[$0] }
            .drive(selectedMessageType)
            .disposed(by: disposeBag)

        Driver.combineLatest(_messages.asDriver(), selectedMessageType.asDriver(), searchText.asDriver()) { _messages, messageType, searchText -> [Message] in
                switch messageType {
                case .timeline:
                    return _messages
                        .filter { !$0.isDraft }
                        .filter {
                            if searchText.isEmpty { return true }
                            return $0.rawMessage.range(of: searchText, options: .caseInsensitive) != nil ||
                                $0.senderKeyUserId.range(of: searchText, options: .caseInsensitive) != nil ||
                                $0.getRecipients().first(where: { messageRecipient in messageRecipient.keyUserId.range(of: searchText, options: .caseInsensitive) != nil } ) != nil
                        }
                        .sorted(by: { lhs, rhs -> Bool in
                            guard let lhsDate = lhs.interpretedAt ?? lhs.composedAt else {
                                return false
                            }

                            guard let rhsDate = rhs.interpretedAt ?? rhs.composedAt else {
                                return true
                            }

                            return lhsDate > rhsDate
                        })
                case .savedDrafts:
                    return _messages
                        .filter { $0.isDraft }
                        .filter {
                            if searchText.isEmpty { return true }
                            return $0.rawMessage.range(of: searchText, options: .caseInsensitive) != nil ||
                                $0.senderKeyUserId.range(of: searchText, options: .caseInsensitive) != nil ||
                                $0.getRecipients().first(where: { messageRecipient in messageRecipient.keyUserId.range(of: searchText, options: .caseInsensitive) != nil }) != nil
                        }
                        .sorted(by: { lhs, rhs -> Bool in
                            guard let lhsDate = lhs.interpretedAt ?? lhs.composedAt else {
                                return false
                            }

                            guard let rhsDate = rhs.interpretedAt ?? rhs.composedAt else {
                                return true
                            }

                            return lhsDate > rhsDate
                        })
                }
            }
            .drive(messages)
            .disposed(by: disposeBag)
    }
    
}

@available(iOS 13.0, *)
extension MessagesViewModel {

    // swiftlint:disable force_cast
    func configureDataSource(tableView: UITableView) {
        diffableDataSource = UITableViewDiffableDataSource<Section, Message>(tableView: tableView) { [weak self] tableView, indexPath, message -> UITableViewCell? in
            guard let `self` = self else { return nil }

            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MessageCardCell.self), for: indexPath) as! MessageCardCell
            MessagesViewModel.configure(messageCardCell: cell, with: message)

            guard let id = message.id else { return cell }
            // cell expand logic
            if let isExpand = self.messageExpandedIDDict[id],
            let maxNumberOfLines = self.messageMaxNumberOfLinesIDDict[id] {
                cell.messageLabel.numberOfLines = isExpand ? 0 : 4
                cell.extraBackgroundViewHeightConstraint.constant = maxNumberOfLines > 4 ? 44 : 0
                let title = isExpand ? L10n.MessageCardCell.Button.Expand.collapse : L10n.MessageCardCell.Button.Expand.expand(maxNumberOfLines)
                cell.expandButton.setTitle(title, for: .normal)
            } else {
                cell.messageLabel.layoutIfNeeded()
                let maxNumberOfLines = cell.messageLabel.maxNumberOfLines
                self.messageExpandedIDDict[id] = false
                self.messageMaxNumberOfLinesIDDict[id] = maxNumberOfLines
                cell.messageLabel.numberOfLines = 4
                cell.extraBackgroundViewHeightConstraint.constant = maxNumberOfLines > 4 ? 44 : 0
                let title = L10n.MessageCardCell.Button.Expand.expand(maxNumberOfLines)
                cell.expandButton.setTitle(title, for: .normal)
            }

            cell.setNeedsLayout()
            cell.layoutIfNeeded()

           return cell
        }   // end let dataSource = …
    }   // end func configureDataSource(:) { … }
    // swiftlint:enable force_cast

}

// MARK: - UITableViewDataSource
extension MessagesViewModel: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.value.count
    }

    // swiftlint:disable force_cast
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: update data source when contact changed

        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MessageCardCell.self), for: indexPath) as! MessageCardCell
        let message = messages.value[indexPath.row]
        MessagesViewModel.configure(messageCardCell: cell, with: message)

        // cell expand logic
        if let isExpand = messageExpandedDict[indexPath],
        let maxNumberOfLines = messageMaxNumberOfLinesDict[indexPath] {
            cell.messageLabel.numberOfLines = isExpand ? 0 : 4
            cell.extraBackgroundViewHeightConstraint.constant = maxNumberOfLines > 4 ? 44 : 0
            let title = isExpand ? L10n.MessageCardCell.Button.Expand.collapse : L10n.MessageCardCell.Button.Expand.expand(maxNumberOfLines)
            cell.expandButton.setTitle(title, for: .normal)
        } else {
            cell.messageLabel.layoutIfNeeded()
            let maxNumberOfLines = cell.messageLabel.maxNumberOfLines
            messageExpandedDict[indexPath] = false
            messageMaxNumberOfLinesDict[indexPath] = maxNumberOfLines
            cell.messageLabel.numberOfLines = 4
            cell.extraBackgroundViewHeightConstraint.constant = maxNumberOfLines > 4 ? 44 : 0
            let title = L10n.MessageCardCell.Button.Expand.expand(maxNumberOfLines)
            cell.expandButton.setTitle(title, for: .normal)
        }

        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        return cell
    }
    // swiftlint:enable force_cast

}

extension MessagesViewModel {

    // configure cell UI
    static func configure(messageCardCell cell: MessageCardCell, with message: Message) {
        // set message content
        cell.messageLabel.text = message.rawMessage

        // set sender info
        let senderInfoView: MessageContactInfoView = {
            let infoView = MessageContactInfoView()
            let senderMeta = PGPUserIDTranslator(userID: message.senderKeyUserId)
            let senderIDLabelColor: UIColor = ProfileService.default.containsKey(longIdentifier: message.senderKeyId) ? .systemGreen : .systemBlue

            infoView.nameLabel.text = MessagesViewModel.retrieveNameBy(longIdentifier: message.senderKeyId, fallbackToMeta: senderMeta)
            infoView.emailLabel.text = senderMeta.email.flatMap { "(\($0))"}
            infoView.shortIDLabel.text = String(message.senderKeyId.suffix(8))
            infoView.shortIDLabel.textColor = senderIDLabelColor

            return infoView
        }()
        cell.signedByStackView.addArrangedSubview(senderInfoView)

        // set recipient(s) info
        let recipeintsInfoViews = message.getRecipients().map { recipient -> MessageContactInfoView in
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

        // set footer
        var leftFooterText = ""
        var rightFooterText = ""
        if message.isDraft {
            leftFooterText = message.composedAt.flatMap { "\($0.timeAgoSinceNow)\(L10n.MessageCardCell.Label.composed)" } ?? ""
            rightFooterText = message.interpretedAt.flatMap { "\($0.timeAgoSinceNow)\(L10n.MessageCardCell.Label.edited)" } ?? ""
        } else {
            if let composedDate = message.composedAt {
                leftFooterText = "\(composedDate.timeAgoSinceNow)\(L10n.MessageCardCell.Label.composed)"
                if let interpretedDate = message.interpretedAt {
                    rightFooterText = "\(interpretedDate.timeAgoSinceNow)\(L10n.MessageCardCell.Label.interpret)"
                }
            } else {
                leftFooterText = message.interpretedAt.flatMap { "\($0.timeAgoSinceNow)\(L10n.MessageCardCell.Label.interpret)"} ?? ""
            }
        }
        cell.leftFooterLabel.text = leftFooterText
        cell.rightFooterLabel.text = rightFooterText
    }

}

extension MessagesViewModel {

    static func retrieveNameBy(longIdentifier: String, fallbackToMeta meta: PGPUserIDTranslator) -> String {
        guard !longIdentifier.isEmpty else {
            return L10n.Common.Label.nameNone
        }

        let contacts = Contact.getOwnerContacts(longIdentifier: longIdentifier)
        if contacts.count == 1 {
            // Display contact's name when only 1 contact owns this key
            return contacts.first?.name ?? meta.name ?? L10n.Common.Label.nameUnknown
        } else {
            if meta.userID.isEmpty {
                return L10n.Common.Label.nameUnknown
            }
            return meta.name ?? L10n.Common.Label.nameUnknown
        }
    }

}
