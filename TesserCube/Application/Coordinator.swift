//
//  Coordinator.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/18.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

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
        case main(message: String?)
        case composeMessage
        case composeMessageTo(keyBridges: [KeyBridge])
        case recomposeMessage(message: Message)
        case interpretMessage
        case importKey
        case pasteKey(needPassphrase: Bool)
        case createKey
        case pickContacts(delegate: PickContactsDelegate?, selectedContacts: [Contact])
        case contactDetail(contactId: Int64)
        case contactEdit(contactId: Int64)
        case settings
        case messageDigitalSignatureSettings(viewModel: MessageDigitalSignatureSettingsViewModel, delegate: MessageDigitalSignatureSettingsViewControllerDelegate)
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
        case .main(let message):
//            guard WizardViewController.didPresentWizard else {
//                UIApplication.shared.keyWindow?.rootViewController = WizardViewController()
//                UIApplication.shared.keyWindow?.makeKeyAndVisible()
//                completion?()
//                return
//            }
//
//            var rootVC: UIViewController
//
//            // Warning: Check if logged after implementation Logging mechanism
//            var logged = true
//            if logged {
//                rootVC = MainTabbarViewController()
//            } else {
//                rootVC = MainTabbarViewController()
//            }
            UIApplication.shared.keyWindow?.rootViewController = MainTabbarViewController()
            UIApplication.shared.keyWindow?.makeKeyAndVisible()
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
        case .interpretMessage:
            let vc = InterpretMessageViewController()
            return vc
        case .importKey:
            let vc = ImportKeyViewController()
            vc.hidesBottomBarWhenPushed = true
            return vc
        case .pasteKey(let needPassphrase):
            let vc = PasteKeyViewController()
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
        }
    }
}

extension Coordinator {
    func handleUrl(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard url.scheme == "tessercube" else { return false }
        guard let host = url.host else { return false }
        guard let urlHost = URLHost(rawValue: host) else { return false }
        
        if case .fullAccess = urlHost {
            if app.canOpenURL(URL(string: UIApplication.openSettingsURLString)!) {
                app.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                return true
            }
        }
        
        guard let rootVC = app.keyWindow?.rootViewController else { return false }
        present(scene: urlHost.scene, from: rootVC, transition: .modal, completion: nil)
        return true
    }
}
