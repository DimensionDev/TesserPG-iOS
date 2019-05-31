//
//  ShareUtil.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/24.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class ShareUtil {

    // share public key
    static func share(key: TCKey, from viewController: UIViewController, over view: UIView?) {
        let armoedKeyString = key.keyRing.publicKeyRing.armored()
        
        let vc = UIActivityViewController(activityItems: [armoedKeyString], applicationActivities: [])
        vc.completionWithItemsHandler = { type, result, items, error in
            
        }

        if let presenter = vc.popoverPresentationController {
            if let view = view {
                presenter.sourceView = view
                presenter.sourceRect = view.bounds
            } else {
                presenter.sourceView = viewController.view
                presenter.sourceRect = CGRect(origin: viewController.view.center, size: .zero)
                presenter.permittedArrowDirections = []
            }
        }
        viewController.present(vc, animated: true)
    }

    static func export(key: TCKey, from viewController: UIViewController, over view: UIView?) {
        let armoedKeyString = key.armored

        let vc = UIActivityViewController(activityItems: [armoedKeyString], applicationActivities: [])
        vc.completionWithItemsHandler = { type, result, items, error in

        }

        if let presenter = vc.popoverPresentationController {
            if let view = view {
                presenter.sourceView = view
                presenter.sourceRect = view.bounds
            } else {
                presenter.sourceView = viewController.view
                presenter.sourceRect = CGRect(origin: viewController.view.center, size: .zero)
                presenter.permittedArrowDirections = []
            }
        }
        viewController.present(vc, animated: true)
    }
    
    static func share(message: String, from viewController: UIViewController, over view: UIView?) {
        let vc = UIActivityViewController(activityItems: [message], applicationActivities: [])
        vc.completionWithItemsHandler = { type, result, items, error in
            
        }

        if let presenter = vc.popoverPresentationController {
            if let view = view {
                presenter.sourceView = view
                presenter.sourceRect = view.bounds
            } else {
                presenter.sourceView = viewController.view
                presenter.sourceRect = CGRect(origin: viewController.view.center, size: .zero)
                presenter.permittedArrowDirections = []
            }
        }
        viewController.present(vc, animated: true)
    }
}
