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
        case deleteWallet(wallet: Wallet, presentingViewController: UIViewController, cell: WalletCardCollectionViewCell, isContextMenu: Bool)
        case claimRedPacket(redPacket: RedPacket, presentingViewController: UIViewController)
        case checkRedPacketDetail(redPacket: RedPacket, presentingViewController: UIViewController)
        case shareRedPacketArmoredMessage(redPacket: RedPacket, presentingViewController: UIViewController, cell: RedPacketCardTableViewCell)
        case cancel

        var title: String {
            switch self {
            case .copyWalletAddress:    return "Copy Wallet Address"
            case .backupMnemonic:       return "Backup Mnemonic"
            case .deleteWallet:         return "Delete"
            case .claimRedPacket:       return "Claim Red Packet"
            case .checkRedPacketDetail: return "Check Red Packet Detail"
            case .shareRedPacketArmoredMessage:
                                        return "Share Red Packet Message"
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
                case .claimRedPacket:       return UIImage(systemName: "envelope.open")
                case .checkRedPacketDetail: return UIImage(systemName: "envelope.open.fill")
                case .shareRedPacketArmoredMessage:
                                            return UIImage(systemName: "doc.on.doc")
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
                case let .claimRedPacket(redPacket, presentingViewController):
                    let viewModel = ClaimRedPacketViewModel(redPacket: redPacket)
                    Coordinator.main.present(scene: .claimRedPacket(viewModel: viewModel), from: presentingViewController, transition: .modal, completion: nil)
                case let .checkRedPacketDetail(redPacket, presentingViewController):
                    let viewModel = RedPacketDetailViewModel(redPacket: redPacket)
                    Coordinator.main.present(scene: .redPacketDetail(viewModel: viewModel), from: presentingViewController, transition: .detail, completion: nil)
                case let .shareRedPacketArmoredMessage(redPacket, presentingViewController, cell):
                    guard let message = RedPacketService.armoredEncPayload(for: redPacket) else {
                        let alertController = UIAlertController(title: "Error", message: "Cannot share red packet message", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alertController.addAction(okAction)
                        presentingViewController.present(alertController, animated: true, completion: nil)
                        return
                    }
                    
                    ShareUtil.share(message: message, from: presentingViewController, over: cell)
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

    private static func deleteMessageAlertController(for wallet: Wallet, cell: WalletCardCollectionViewCell) -> UIAlertController {
        let walletName = cell.walletCardView.headerLabel.text
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

    func tableView(_ tableView: UITableView, presentingViewController: UIViewController, isContextMenu: Bool, actionsforRowAt indexPath: IndexPath) -> [ContextMenuAction]? {
        switch WalletsViewModel.Section.allCases[indexPath.section] {
        case .wallet:
            return nil

        case .redPacket:
            guard let cell = tableView.cellForRow(at: indexPath) as? RedPacketCardTableViewCell else {
                return nil
            }
            return sourceView(cell, presentingViewController: presentingViewController, isContextMenu: isContextMenu, actionsForRowAt: indexPath)
        }   // end switch section

    }
    
    func collectionView(_ collectionView: UICollectionView, presentingViewController: UIViewController, isContextMenu: Bool, actionsForRowAt indexPath: IndexPath) -> [ContextMenuAction]? {
        switch WalletsViewModel.Section.allCases[indexPath.section] {
        case .wallet:
            guard let cell = collectionView.cellForItem(at: indexPath) as? WalletCardCollectionViewCell else {
                return nil
            }
            return sourceView(cell, presentingViewController: presentingViewController, isContextMenu: isContextMenu, actionsForRowAt: indexPath)
        case .redPacket:
            return nil
        }
    }
    
    private func sourceView(_ sourceView: UIView, presentingViewController: UIViewController, isContextMenu: Bool, actionsForRowAt indexPath: IndexPath) -> [ContextMenuAction]? {
        switch WalletsViewModel.Section.allCases[indexPath.section] {
        case .wallet:
            guard let cell = sourceView as? WalletCardCollectionViewCell else {
                return nil
            }
            let walletModel = walletModels.value[indexPath.row]
            let wallet = walletModel.wallet
            // - Copy Wallet Address
            // - Delete
            // - Cancel
            return [
                Action.copyWalletAddress(address: walletModel.address),
                Action.backupMnemonic(wallet: wallet, presentingViewController: presentingViewController),
                Action.deleteWallet(wallet: wallet, presentingViewController: presentingViewController, cell: cell, isContextMenu: isContextMenu),
                Action.cancel
            ]
            
        case .redPacket:
            guard let cell = sourceView as? RedPacketCardTableViewCell else {
                return nil
            }
            let redPacket = filteredRedPackets.value[indexPath.row].redPacket
            
            switch redPacket.status {
            case .normal, .incoming:
                return [
                    Action.claimRedPacket(redPacket: redPacket, presentingViewController: presentingViewController),
                    Action.checkRedPacketDetail(redPacket: redPacket, presentingViewController: presentingViewController),
                    Action.shareRedPacketArmoredMessage(redPacket: redPacket, presentingViewController: presentingViewController, cell: cell),
                    Action.cancel
                ]
            default:
                return [
                    Action.shareRedPacketArmoredMessage(redPacket: redPacket, presentingViewController: presentingViewController, cell: cell),
                    Action.checkRedPacketDetail(redPacket: redPacket, presentingViewController: presentingViewController),
                    Action.cancel
                ]
            }
        }
    }

}
