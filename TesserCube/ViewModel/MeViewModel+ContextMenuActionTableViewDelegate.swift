//
//  MeViewModel+ContextMenuActionTableViewDelegate.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-8-29.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import ConsolePrint

extension MeViewModel {

    enum Action: ContextMenuAction {

        case sharePublic(key: TCKey, presentingViewController: UIViewController, cell: UITableViewCell)
        case exportPrivate(key: TCKey, presentingViewController: UIViewController, cell: UITableViewCell)
        case delete(key: TCKey, presentingViewController: UIViewController, cell: UITableViewCell)
        case cancel

        var title: String {
            switch self {
            case .sharePublic:       return L10n.MeViewController.Action.Button.share
            case .exportPrivate:     return L10n.MeViewController.Action.Button.export
            case .delete:            return L10n.Common.Button.delete
            case .cancel:               return L10n.Common.Button.cancel
            }
        }

        var discoverabilityTitle: String? {
            return nil
        }

        var image: UIImage? {
            if #available(iOS 13.0, *) {
                switch self {
                case .sharePublic:
                    return UIImage(systemName: "square.and.arrow.up")
                case .exportPrivate:
                    return UIImage(systemName: "square.and.arrow.up.on.square")
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

        @available(iOS 13.0, *)
        var attributes: UIMenuElement.Attributes {
            switch self {
            case .delete, .exportPrivate:
                return [.destructive]
            default:
                return []
            }
        }

        @available(iOS 13.0, *)
        var state: UIMenuElement.State {
            return .off
        }

        var style: UIAlertAction.Style {
            switch self {
            case .delete, .exportPrivate:   return .destructive
            case .cancel:                   return .cancel
            default:                        return .default
            }
        }

        var handler: () -> Void {
            return {
                switch self {
                case let .sharePublic(key, presentingViewController, cell):
                    ShareUtil.share(key: key, from: presentingViewController, over: cell)
                case let .exportPrivate(key, presentingViewController, cell):
                    ShareUtil.export(key: key, from: presentingViewController, over: cell)
                case let .delete(key, presentingViewController, cell):
//                    guard let keyRecord = key.keyRecord else {
//                        return
//                    }

                    let deleteConfirmAlertController: UIAlertController = {
                        let confirmMessage = L10n.MeViewController.Action.Button.confirmDeleteKey + key.shortIdentifier
                        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                        alertVC.addAction(title: confirmMessage, style: .destructive, isEnabled: true) { _ in
                            try? KeyRecord.remove(keys: [key.longIdentifier])
                        }
                        alertVC.addAction(title: L10n.Common.Button.cancel, style: .cancel, isEnabled: true)
                        if let presenter = alertVC.popoverPresentationController {
                            presenter.sourceView = cell
                            presenter.sourceRect = cell.bounds
                        }
                        return alertVC
                    }()
                    presentingViewController.present(deleteConfirmAlertController, animated: true, completion: nil)

                case .cancel:
                    break
                }
            }
        }

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

    }

}

// MARK: - ContextMenuActionTableViewDelegate
extension MeViewModel: ContextMenuActionTableViewDelegate {

    func tableView(_ tableView: UITableView, presentingViewController: UIViewController, actionsforRowAt indexPath: IndexPath) -> [ContextMenuAction] {
        guard let cell = tableView.cellForRow(at: indexPath) as? KeyCardCell,
        case let .TCKey(key) = cell.keyValue else {
            return []
        }

        return [
            Action.sharePublic(key: key, presentingViewController: presentingViewController, cell: cell),
            Action.exportPrivate(key: key, presentingViewController: presentingViewController, cell: cell),
            Action.delete(key: key, presentingViewController: presentingViewController, cell: cell),
            Action.cancel
        ]
    }

}
