//
//  MessagesViewModel.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/22.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SwifterSwift
import RxSwift
import RxCocoa
import DateToolsSwift

class MessagesViewModel: NSObject {

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
    var messageExpandedDict: [IndexPath : Bool] = [:]
    var messageMaxNumberOfLinesDict: [IndexPath : Int] = [:]

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
                            return $0.rawMessage.contains(searchText, caseSensitive: false) ||
                                $0.senderKeyUserId.contains(searchText, caseSensitive: false) ||
                                $0.getRecipients().first(where: { messageRecipient in messageRecipient.keyUserId.contains(searchText, caseSensitive: false) ?? false } ) != nil
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
                            return $0.rawMessage.contains(searchText, caseSensitive: false) ||
                                $0.senderKeyUserId.contains(searchText, caseSensitive: false) ||
                                $0.getRecipients().first(where: { messageRecipient in messageRecipient.keyUserId.contains(searchText, caseSensitive: false)
                                }) != nil
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
        let messageModal = messages.value[indexPath.row]
        cell.messageLabel.text = messageModal.rawMessage

        let senderInfoView = MessageContactInfoView()

        // Discuss: Should we put following username mechanism in message's extension?
        let senderMeta = PGPUserIDTranslator(userID: messageModal.senderKeyUserId)
        senderInfoView.nameLabel.text = retrieveNameBy(longIdentifier: messageModal.senderKeyId, fallbackToMeta: senderMeta)
        senderInfoView.emailLabel.text = senderMeta.email.flatMap { "(\($0))"}
        senderInfoView.shortIDLabel.text = String(messageModal.senderKeyId.suffix(8))
        senderInfoView.shortIDLabel.textColor = Asset.shortIdBlue.color
        cell.signedByStackView.addArrangedSubview(senderInfoView)

        let recipeintsInfoViews = messageModal.getRecipients().map { recipient -> MessageContactInfoView in
            let infoView = MessageContactInfoView()
            let meta = PGPUserIDTranslator(userID: recipient.keyUserId)
            infoView.nameLabel.text = retrieveNameBy(longIdentifier: recipient.keyId, fallbackToMeta: meta)
            infoView.emailLabel.text = meta.email.flatMap { "(\($0))"}
            infoView.shortIDLabel.text = String(recipient.keyId.suffix(8))
            return infoView
        }
        cell.recipeintsStackView.addArrangedSubviews(recipeintsInfoViews)
        
        if recipeintsInfoViews.isEmpty {
            let infoView = MessageContactInfoView()
            infoView.nameLabel.text = L10n.Common.Label.nameNone
            cell.recipeintsStackView.addArrangedSubview(infoView)
        }

        var leftFooterText = ""
        var rightFooterText = ""
        if messageModal.isDraft {
            leftFooterText = messageModal.composedAt.flatMap { "\($0.timeAgoSinceNow)\(L10n.MessageCardCell.Label.composed)" } ?? ""
            rightFooterText = messageModal.interpretedAt.flatMap { "\($0.timeAgoSinceNow)\(L10n.MessageCardCell.Label.edited)" } ?? ""
        } else {
            if let composedDate = messageModal.composedAt {
                leftFooterText = "\(composedDate.timeAgoSinceNow)\(L10n.MessageCardCell.Label.composed)"
                if let interpretedDate = messageModal.interpretedAt {
                    rightFooterText = "\(interpretedDate.timeAgoSinceNow)\(L10n.MessageCardCell.Label.interpret)"
                }
            } else {
                leftFooterText = messageModal.interpretedAt.flatMap { "\($0.timeAgoSinceNow)\(L10n.MessageCardCell.Label.interpret)"} ?? ""
            }
        }
        cell.leftFooterLabel.text = leftFooterText
        cell.rightFooterLabel.text = rightFooterText

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

    private func retrieveNameBy(longIdentifier: String, fallbackToMeta meta: PGPUserIDTranslator) -> String {
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
