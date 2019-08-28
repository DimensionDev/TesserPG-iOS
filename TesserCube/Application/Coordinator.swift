//
//  Coordinator.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/18.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import DMSOpenPGP

class Coordinator {
    
    static let main = Coordinator()
    
    enum Transition {
        case root(in: UIWindow)
        case modal
        case detail
        case alert
        case custom
    }
    
    enum Scene {
        case main(message: String?, window: UIWindow)
        case composeMessage
        case composeMessageTo(keyBridges: [KeyBridge])
        case recomposeMessage(message: Message)
        case writeReply(to: [KeyBridge], from: KeyBridge?)
        case interpretMessage
        case importKey
        case pasteKey(armoredKey: String?, needPassphrase: Bool)
        case createKey
        case pickContacts(delegate: PickContactsDelegate?, selectedContacts: [Contact])
        case contactDetail(contactId: Int64)
        case contactEdit(contactId: Int64)
        case settings
        case messageDigitalSignatureSettings(viewModel: MessageDigitalSignatureSettingsViewModel, delegate: MessageDigitalSignatureSettingsViewControllerDelegate)
        case importKeyConfirm(key: TCKey, passphrase: String?)
        case interpretAction(message: String)
        case brokenMessage(message: String?)
    }
    
    enum URLHost: String {
        case fullAccess
        
        var scene: Scene {
            switch self {
            case .fullAccess:
                return .createKey
            }
        }
    }
    
    func present(scene: Scene, from sender: UIViewController?, transition: Transition = .detail, completion: (() -> Void)? = nil) {
        switch scene {
        case let .main(message, window):
            if #available(iOS 13, *) {
                window.rootViewController = MainTabbarViewController()
                window.makeKeyAndVisible()
            } else {
                UIApplication.shared.keyWindow?.rootViewController = MainTabbarViewController()
                UIApplication.shared.keyWindow?.makeKeyAndVisible()
            }
            completion?()
        default:
            let vc = get(scene: scene)
            switch transition {
            case .detail:
                if let naviVC = sender as? UINavigationController {
                    naviVC.pushViewController(vc, completion: completion)
                } else {
                    sender?.navigationController?.pushViewController(vc, completion: completion)
                }
            case .modal:
                let navigationController = UINavigationController(rootViewController: vc)
                if let adaptivePresentationControllerDelegate = vc as? UIAdaptivePresentationControllerDelegate {
                    navigationController.presentationController?.delegate = adaptivePresentationControllerDelegate
                }
                (sender?.navigationController ?? sender)?.present(navigationController, animated: true, completion: completion)
            default:
                return
            }
        }
    }

}

extension Coordinator {
    private func get(scene: Scene) -> UIViewController {
        switch scene {
        case .main:
            return MainTabbarViewController()
        case .composeMessage:
            let vc = ComposeMessageViewController()
            return vc
        case .composeMessageTo(let keybridges):
            let vc = ComposeMessageViewController()
            vc.viewModel.keyBridges.accept(keybridges)
            return vc
        case .recomposeMessage(let message):
            let vc = ComposeMessageViewController()
            vc.viewModel.message.accept(message)
            return vc
        case let .writeReply(to, from):
            let vc = ComposeMessageViewController()
            vc.viewModel.keyBridges.accept(to)
            vc.viewModel.senderKeyBridge = from
            return vc
        case .interpretMessage:
            let vc = InterpretMessageViewController()
            return vc
        case .importKey:
            let vc = ImportKeyViewController()
            vc.hidesBottomBarWhenPushed = true
            return vc
        case let .pasteKey(armoredKey, needPassphrase):
            let vc = PasteKeyViewController()
            vc.armoredKey = armoredKey
            vc.needPassphrase = needPassphrase
            vc.hidesBottomBarWhenPushed = true
            return vc
        case .createKey:
            let vc = CreateNewKeyViewController()
            vc.hidesBottomBarWhenPushed = true
            return vc
        case .pickContacts(let delegate, let selectedContacts):
            let vc = ContactsListViewController()
            vc.isPickContactMode = true
            vc.delegate = delegate
            vc.preSelectedContacts = selectedContacts
            vc.hidesBottomBarWhenPushed = true
            return vc
        case .contactDetail(let contactId):
            let vc = ContactDetailViewController(contactId: contactId)
            vc.hidesBottomBarWhenPushed = true
            return vc
        case .contactEdit(let contactId):
            let vc = ContactEditViewController(contactId: contactId)
            vc.hidesBottomBarWhenPushed = true
            return vc
        case .settings:
            let vc = SettingsViewController()
            vc.hidesBottomBarWhenPushed = true
            return vc
        case .messageDigitalSignatureSettings(let viewModel, let delegate):
            let vc = MessageDigitalSignatureSettingsViewController()
            vc.viewModel = viewModel
            vc.delegate = delegate
            return vc
        case .importKeyConfirm(let key, let passphrase):
            if let passphrase = passphrase {
                let vc = ImportPrivateKeyConfirmViewController()
                vc.tcKey = key
                vc.passphrase = passphrase
                vc.hidesBottomBarWhenPushed = true
                return vc
            } else {
                let vc = ImportPublicKeyConfirmViewController()
                vc.tcKey = key
                vc.hidesBottomBarWhenPushed = true
                return vc
            }
        case .interpretAction(let message):
            let vc = InterpretActionViewController()
            vc.viewModel.inputTexts = [message]
            return vc
        case .brokenMessage(let message):
            let vc = BrokenMessageViewController()
            vc.viewModel.message.accept(message)
            return vc
        }
    }
}

extension Coordinator {
     
    func handleUrl(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        switch url.scheme {
        case "file":
            let plainText = try? String(contentsOf: url, encoding: .utf8)

            // FIXME: SceneDelegate
            let rootViewController = UIApplication.shared.keyWindow?.rootViewController

            guard let message = plainText, !message.isEmpty else {
                Coordinator.main.present(scene: .brokenMessage(message: plainText), from: rootViewController, transition: .modal)
                return true
            }

            let hasSecretKey = DMSPGPKeyRing.extractSecretKeyBlock(from: message) != nil
            guard !hasSecretKey else {
                Coordinator.main.present(scene: .pasteKey(armoredKey: message, needPassphrase: true), from: rootViewController, transition: .modal, completion: nil)
                return true
            }

            let hasPublicKey = DMSPGPKeyRing.extractPublicKeyBlock(from: message) != nil
            guard !hasPublicKey else {
                Coordinator.main.present(scene: .pasteKey(armoredKey: message, needPassphrase: false), from: rootViewController, transition: .modal, completion: nil)
                return true
            }

            Coordinator.main.present(scene: .interpretAction(message: message), from: rootViewController, transition: .modal, completion: nil)
            return true

        case "tessercube":
            guard let host = url.host, let urlHost = URLHost(rawValue: host) else {
                return false
            }

            switch urlHost {
            case .fullAccess:
                if app.canOpenURL(URL(string: UIApplication.openSettingsURLString)!) {
                    app.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                    return true
                } else {
                    return false
                }
            }

        default:
            return false
        }
    }
    
}
