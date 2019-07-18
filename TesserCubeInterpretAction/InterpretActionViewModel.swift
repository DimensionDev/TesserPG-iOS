//
//  InterpretActionViewModel.swift
//  TesserCubeInterpretAction
//
//  Created by Cirno MainasuK on 2019-7-17.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import DMSOpenPGP

final class InterpretActionViewModel: NSObject {

    private let disposeBag = DisposeBag()

    // Input
    var inputTexts: [String] = []
    var messageExpandedDict: [IndexPath : Bool] = [:]
    var messageMaxNumberOfLinesDict: [IndexPath : Int] = [:]
    var copyAction = PublishRelay<UIButton>()
    var writeAction = PublishRelay<UIButton>()

    // Output
    let title = BehaviorRelay<String>(value: L10n.InterpretActionViewController.Title.messageInterpreting)
    let armoredMessage = BehaviorRelay<String?>(value: nil)
    let message = BehaviorRelay<Message?>(value: nil)
    let availableActions = BehaviorRelay<[Action]>(value: [])

    override init() {
        super.init()

        armoredMessage.asDriver()
            .flatMapLatest { message in
                return Driver.just(message.flatMap { try? ProfileService.default.decryptMessage($0) })
            }
            .drive(message)
            .disposed(by: disposeBag)

        message.asDriver()
            .drive(onNext: { [weak self] message in
                guard let message = message, let `self` = self else { return }

                // set available actions
                if ProfileService.default.containsKey(longIdentifier: message.senderKeyId) {
                    self.availableActions.accept([.copy, .reply])
                } else {
                    self.availableActions.accept([.copy])
                }

                // notify main app message update (interpret date changed)
                WormholdService.shared.wormhole.clearMessageContents(forIdentifier: WormholdService.MessageIdentifier.interpretActionExtensionDidUpdateMessage.rawValue)
                WormholdService.shared.wormhole.passMessageObject("interpretActionExtensionDidUpdateMessage" as NSCoding, identifier: WormholdService.MessageIdentifier.interpretActionExtensionDidUpdateMessage.rawValue)
            })
            .disposed(by: disposeBag)

        message.asDriver()
            .skip(1)
            .drive(onNext: { message in
                let title = message != nil ? L10n.InterpretActionViewController.Title.messageInterpreted : L10n.InterpretActionViewController.Title.brokenMessage
                self.title.accept(title)
            })
            .disposed(by: disposeBag)

        // handler actions
        copyAction
            .observeOn(MainScheduler.asyncInstance)
            .do(onNext: { sender in
                sender.setTitle(L10n.InterpretActionViewController.Action.Button.copied, for: .normal)
                UIPasteboard.general.string = self.message.value?.rawMessage
            })
            .debounce(1, scheduler: MainScheduler.asyncInstance)
            .delay(1, scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { sender in
                sender.setTitle(L10n.InterpretActionViewController.Action.Button.copyContent, for: .normal)
            })
            .disposed(by: disposeBag)

    }   // end init()

}

extension InterpretActionViewModel {

    enum Action {
        case copy
        case reply
    }

}

extension InterpretActionViewModel {

    func finalizeInput() {
        // Prevent user change messages database in main app cause database not sync between app and extension.
        let latestMessages = ProfileService.default.loadMessages()
        ProfileService.default.messages.accept(latestMessages)

        let message = inputTexts.first { DMSPGPDecryptor.verify(armoredMessage: $0) }
        armoredMessage.accept(message)
    }

}

// MARK: - UITableViewDataSource
extension InterpretActionViewModel: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return message.value != nil ? 1 : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MessageCardCell.self), for: indexPath) as! MessageCardCell

        guard let message = message.value else {
            return cell
        }

        MessagesViewModel.configure(messageCardCell: cell, with: message)

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

}
