//
//  WalletsViewModel+ContextMenuActionTableViewDelegate.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-12.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

extension WalletsViewModel {

    enum Action: ContextMenuAction {

        case copyWalletAddress(address: String)
        case backupMnemonic(wallet: Wallet, presentingViewController: UIViewController)
        case deleteWallet(wallet: Wallet, presentingViewController: UIViewController, cell: WalletCardTableViewCell, isContextMenu: Bool)
        case cancel

        var title: String {
            switch self {
            case .copyWalletAddress:    return "Copy Wallet Address"
            case .backupMnemonic:       return "Backup Mnemonic"
            case .deleteWallet:         return "Delete"
            case .cancel:               return L10n.Common.Button.cancel
            }
        }

        var discoverabilityTitle: String? {
            return nil
        }

        var image: UIImage? {
            if #available(iOS 13.0, *) {
                switch self {
                case .copyWalletAddress:    return UIImage(systemName: "doc.on.doc")
                case .backupMnemonic:       return UIImage(systemName: "pencil.circle")
                case .deleteWallet:         return UIImage(systemName: "trash")
                default:                    return nil
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
            case .deleteWallet:     return [.destructive]
            default:                return []
            }
        }

        @available(iOS 13.0, *)
        var state: UIMenuElement.State {
            return .off
        }

        var style: UIAlertAction.Style {
            switch self {
            case .deleteWallet:     return .destructive
            case .cancel:           return .cancel
            default:                return .default
            }
        }

        var handler: () -> Void {
            return {
                switch self {
                case let .copyWalletAddress(address):
                    UIPasteboard.general.string = address
                case let .backupMnemonic(wallet, presentingViewController):
                    let viewModel = BackupMnemonicCollectionViewModel(wallet: wallet)
                    Coordinator.main.present(scene: .backupMnemonic(viewModel: viewModel), from: presentingViewController, transition: .modal, completion: nil)
                case let .deleteWallet(wallet, presentingViewController, cell, isContextMenu):
                    if isContextMenu {
                        WalletService.default.remove(wallet: wallet)
                    } else {
                        let confirmDeleteAlertController = WalletsViewModel.deleteMessageAlertController(for: wallet, cell: cell)
                        presentingViewController.present(confirmDeleteAlertController, animated: true, completion: nil)
                    }

                case .cancel:
                    break
                }
            }
        }

        @available(iOS 13.0, *)
        var menuElement: UIMenuElement? {
            let finalAction = UIAction(title: title, image: image, identifier: identifier, discoverabilityTitle: discoverabilityTitle, attributes: attributes, state: state, handler: { _ in self.handler() })
            switch self {
            case .deleteWallet:
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

extension WalletsViewModel {

    private static func deleteMessageAlertController(for wallet: Wallet, cell: WalletCardTableViewCell) -> UIAlertController {
        let walletName = cell.headerLabel.text
        let title = ["Yes. Delete", walletName].compactMap { $0 }.joined(separator: " ")

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: title, style: .destructive) { _ in
            WalletService.default.remove(wallet: wallet)
        }
        alertController.addAction(deleteAction)
        let cancelAction = UIAlertAction(title: L10n.Common.Button.cancel, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = cell
            presenter.sourceRect = cell.bounds
        }

        return alertController
    }

}

// MARK: - ContextMenuActionTableViewDelegate
extension WalletsViewModel: ContextMenuActionTableViewDelegate {

    func tableView(_ tableView: UITableView, presentingViewController: UIViewController, actionsforRowAt indexPath: IndexPath, isContextMenu: Bool) -> [ContextMenuAction] {
        guard let cell = tableView.cellForRow(at: indexPath) as? WalletCardTableViewCell else {
            return []
        }

        let wallet = walletModels.value[indexPath.row].wallet

        // - Copy Wallet Address
        // - Delete
        // - Cancel
        return [
            Action.copyWalletAddress(address: cell.captionLabel.text ?? ""),
            Action.backupMnemonic(wallet: wallet, presentingViewController: presentingViewController),
            Action.deleteWallet(wallet: wallet, presentingViewController: presentingViewController, cell: cell, isContextMenu: isContextMenu),
            Action.cancel
        ]
    }

}
