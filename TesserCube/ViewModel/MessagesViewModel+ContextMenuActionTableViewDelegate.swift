//
//  MessagesViewModel+ContextMenuActionTableViewDelegate.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-8-29.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import DMSGoPGP
import ConsolePrint

extension MessagesViewModel {

    enum Action: ContextMenuAction {
        case copyMessageContent(message: Message)
        case copyPayload(message: Message)

        case shareArmoredMessage(message: Message, presentingViewController: UIViewController, cell: UITableViewCell)
        case recomposeMessage(message: Message, presentingViewController: UIViewController)
        // draft
        case edit(message: Message, presentingViewController: UIViewController)
        case finishDraft(message: Message, presentingViewController: UIViewController, disposeBag: DisposeBag)
        
        // red packet
        // case claim(message: Message, redPacket: RedPacket, presentingViewController: UIViewController)
        // case refund(message: Message, redPacket: RedPacket, presentingViewController: UIViewController)

        case delete(message: Message, presentingViewController: UIViewController, cell: UITableViewCell)
        case cancel

        var title: String {
            switch self {
            case .copyMessageContent:   return L10n.MessagesViewController.Action.Button.copyMessageContent
            case .copyPayload:          return L10n.MessagesViewController.Action.Button.copyRawPayload
            case .shareArmoredMessage(let message, _, _):
                let isCleartextMessage: Bool = {
                    var error: NSError?
                    _ = CryptoNewClearTextMessageFromArmored(message.encryptedMessage, &error)
                    return error == nil
                }()
                return isCleartextMessage ? L10n.MessagesViewController.Action.Button.shareSignedMessage : L10n.MessagesViewController.Action.Button.shareEncryptedMessage
            case .recomposeMessage:     return L10n.MessagesViewController.Action.Button.reCompose
            case .edit:                 return L10n.Common.Button.edit
            case .finishDraft:          return L10n.MessagesViewController.Action.Button.markAsFinished
            // case .claim:                return "Claim"
            // case .refund:               return "Refund"
            case .delete:               return L10n.Common.Button.delete
            case .cancel:               return L10n.Common.Button.cancel
            }
        }

        var image: UIImage? {
            if #available(iOS 13.0, *) {
                switch self {
                case .shareArmoredMessage:
                    return UIImage(systemName: "square.and.arrow.up")
                case .copyMessageContent:
                    return UIImage(systemName: "doc.on.clipboard")
                case .copyPayload:
                    return UIImage(systemName: "doc.on.clipboard.fill")
                case .edit, .recomposeMessage:
                    return UIImage(systemName: "square.and.pencil")
                case .finishDraft:
                    return UIImage(systemName: "signature")
                // case .claim:
                //     return UIImage(systemName: "envelope.open")
                // case .refund:
                //     return UIImage(systemName: "envelope.circle")
                case .delete:
                    return UIImage(systemName: "trash")
                default:
                    return nil
                }
            } else {
                return nil
            }
        }

        @available(iOS 13.0, *)
        var identifier: UIAction.Identifier? {
            return nil
        }

        var discoverabilityTitle: String? {
            return nil
        }

        @available(iOS 13.0, *)
        var attributes: UIMenuElement.Attributes {
            switch self {
            case .delete:   return [.destructive]
            default:        return []
            }

        }

        @available(iOS 13.0, *)
        var state: UIMenuElement.State {
            return .off
        }

        var style: UIAlertAction.Style {
            switch self {
            case .delete:   return .destructive
            case .cancel:   return .cancel
            default:        return .default
            }
        }

        var handler: () -> Void {
            return {
                switch self {
                case let .copyMessageContent(message):
                    UIPasteboard.general.string = message.rawMessage

                case let .copyPayload(message):
                    UIPasteboard.general.string = message.encryptedMessage

                case let .shareArmoredMessage(message, presentingViewController, cell):
                    ShareUtil.share(message: message.encryptedMessage, from: presentingViewController, over: cell)

                case let .recomposeMessage(message, presentingViewController):
                    Coordinator.main.present(scene: .recomposeMessage(message: message), from: presentingViewController, transition: .modal, completion: nil)

                case let .edit(message, presentingViewController):
                    Coordinator.main.present(scene: .recomposeMessage(message: message), from: presentingViewController, transition: .modal, completion: nil)

                case let .finishDraft(message, presentingViewController, disposeBag):
                    consolePrint(message.senderKeyId)
                    let senderKey: TCKey? = ProfileService.default.keys.value.first(where: { key -> Bool in
                        return key.longIdentifier == message.senderKeyId
                    })
                    let recipientKeys = message.getRecipients().compactMap { messageRecipient in
                        return ProfileService.default.keys.value.first(where: { key in key.longIdentifier == messageRecipient.keyId })
                    }
                    ComposeMessageViewModel.composeMessage(message.rawMessage, to: recipientKeys, from: senderKey, password: nil)
                        .subscribeOn(ConcurrentDispatchQueueScheduler.init(qos: .userInitiated))
                        .observeOn(MainScheduler.instance)
                        .subscribe(onSuccess: { armored in
                            do {
                                var message = message
                                let rawMessage = message.rawMessage
                                try message.updateDraftMessage(senderKeyID: senderKey?.longIdentifier ?? "", senderKeyUserID: senderKey?.userID ?? "", rawMessage: rawMessage, recipients: recipientKeys, isDraft: false, armoredMessage: armored)
                            } catch {
                                consolePrint(error.localizedDescription)
                            }
                        }, onError: { error in
                            let message = (error as? TCError)?.errorDescription ?? error.localizedDescription
                            presentingViewController.showSimpleAlert(title: L10n.Common.Alert.error, message: message)
                        })
                        .disposed(by: disposeBag)
                // case let .claim(message, redPacket, presentingViewController):
                //     let viewModel = ClaimRedPacketViewModel(redPacket: redPacket)
                //     Coordinator.main.present(scene: .claimRedPacket(viewModel: viewModel), from: presentingViewController, transition: .modal, completion: nil)
                //
                // case let .refund(message, redPacket, presentingViewController):
                //     // TODO:
                //     let alertController = UIAlertController(title: "Refund Fail", message: "Please Refund After Red Packet Expired", preferredStyle: .alert)
                //     let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                //     alertController.addAction(okAction)
                //     presentingViewController.present(alertController, animated: true, completion: nil)

                case let .delete(message, presentingViewController, cell):
                    if #available(iOS 13.0, *) {
                        ProfileService.default.delete(messages: [message])
                    } else {
                        let deleteMessageAlertController = MessagesViewModel.deleteMessageAlertController(for: message, cell: cell)
                        presentingViewController.present(deleteMessageAlertController, animated: true, completion: nil)
                    }

                case .cancel:
                    // do nothing
                    break
                }   // end switch
            }   // end return
        }   // end handler: () -> Void

        @available(iOS 13.0, *)
        var menuElement: UIMenuElement? {
            let finalAction = UIAction(title: title, image: image, identifier: identifier, discoverabilityTitle: discoverabilityTitle, attributes: attributes, state: state, handler: { _ in self.handler() })
            switch self {
            case .delete:
                return UIMenu(title: title, image: image, identifier: nil, options: [.destructive], children: [finalAction])
            case .cancel:
                return nil
            default:
                return finalAction
            }
        }

        var alertAction: UIAlertAction {
            return UIAlertAction(title: title, style: style, handler: { _ in self.handler() })
        }

    }   // end enum Actions

    private static func deleteMessageAlertController(for message: Message, cell: UITableViewCell) -> UIAlertController {
        let alertController = UIAlertController(title: L10n.MessagesViewController.Alert.Title.deleteMessage, message: nil, preferredStyle: .actionSheet)

        let confirmAction = UIAlertAction(title: L10n.Common.Button.delete, style: .destructive, handler: { _ in
            ProfileService.default.delete(messages: [message])
        })
        alertController.addAction(confirmAction)

        let cancelAction = UIAlertAction(title: L10n.Common.Button.cancel, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = cell
            presenter.sourceRect = cell.bounds
        }
        return alertController
    }

    private static func cancelAlertAction() -> UIAlertAction {
        return UIAlertAction(title: L10n.Common.Button.cancel, style: .cancel, handler: nil)
    }

}

// MARK: - ContextMenuActionTableViewDelegate
extension MessagesViewModel: ContextMenuActionTableViewDelegate {

    func tableView(_ tableView: UITableView, presentingViewController: UIViewController, actionsforRowAt indexPath: IndexPath, isContextMenu: Bool) -> [ContextMenuAction] {
        let message = messages.value[indexPath.row]

        if let cell = tableView.cellForRow(at: indexPath) as? MessageCardCell {
            if message.isDraft {
                // Draft:
                //  - Edit
                //  - Finish Draft (markAsFinished)
                //  - Delete
                //  - Cancel
                return [
                    Action.edit(message: message, presentingViewController: presentingViewController),
                    Action.finishDraft(message: message, presentingViewController: presentingViewController, disposeBag: self.disposeBag),
                    Action.delete(message: message, presentingViewController: presentingViewController, cell: cell),
                    Action.cancel,
                ]
            } else {
                let isSignedByOthers: Bool = {
                    let signatureKey = ProfileService.default.keys.value
                        .filter { $0.hasSecretKey }
                        .first(where: { key in key.longIdentifier == message.senderKeyId })
                    return signatureKey == nil && message.composedAt == nil
                }()

                if isSignedByOthers {
                    // Sign by other so message is not editable
                    // Message from others:
                    //  - Copy Message Content
                    //  - COpy Enctyped Message
                    //  - Delete
                    //  - Cancel
                    return [
                        Action.copyMessageContent(message: message),
                        Action.copyPayload(message: message),
                        Action.delete(message: message, presentingViewController: presentingViewController, cell: cell),
                        Action.cancel,
                    ]
                } else {
                    // Compose on this device and is editable
                    // Message from self:
                    //  - Share Encrypted Message
                    //  - Copy Message Content
                    //  - Re-Compose
                    //  - Delete
                    //  - Cancel
                    return [
                        Action.shareArmoredMessage(message: message, presentingViewController: presentingViewController, cell: cell),
                        Action.copyMessageContent(message: message),
                        Action.recomposeMessage(message: message, presentingViewController: presentingViewController),
                        Action.delete(message: message, presentingViewController: presentingViewController, cell: cell),
                        Action.cancel,
                    ]
                }
            }   // end if … else …
        }   // MessageCardCell
        
        /*
        if let cell = tableView.cellForRow(at: indexPath) as? RedPacketCardTableViewCell,
        let redPacket = RedPacketService.shared.redPacket(from: message) {
            // Red Packet:
            //  - Delete
            //  - Cancel
            
            switch redPacket.status {
            case .initial, .pending, .fail, .claimed, .empty, .expired:
                return [
                    Action.refund(message: message, redPacket: redPacket, presentingViewController: presentingViewController),
                    Action.shareArmoredMessage(message: message, presentingViewController: presentingViewController, cell: cell),
                    Action.delete(message: message, presentingViewController: presentingViewController, cell: cell),
                    Action.cancel,
                ]
            case .incoming, .normal:
                return [
                    Action.claim(message: message, redPacket: redPacket, presentingViewController: presentingViewController),
                    Action.refund(message: message, redPacket: redPacket, presentingViewController: presentingViewController),
                    Action.shareArmoredMessage(message: message, presentingViewController: presentingViewController, cell: cell),
                    Action.delete(message: message, presentingViewController: presentingViewController, cell: cell),
                    Action.cancel,
                ]
            case .claim_pending:
                return [
                    Action.cancel,
                ]
            case .refund_pending:
                return [
                    Action.cancel,
                ]
            case .refunded:
                return [
                    Action.cancel,
                ]
            }
        }
         */
        
        return [
            Action.cancel,
        ]
    }

}
