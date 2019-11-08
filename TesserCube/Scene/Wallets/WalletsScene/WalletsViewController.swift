//
//  WalletsViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-6.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class WalletsViewController: TCBaseViewController {

    override func configUI() {
        super.configUI()

        title = L10n.MainTabbarViewController.TabBarItem.Wallets.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(WalletsViewController.addBarButtonItemPressed(_:)))
    }

}

extension WalletsViewController {

    @objc private func addBarButtonItemPressed(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let createWalletAction = UIAlertAction(title: "Create Wallet", style: .default) { _ in
            Coordinator.main.present(scene: .createWallet, from: self, transition: .modal, completion: nil)
        }
        alertController.addAction(createWalletAction)
        let importWalletAction = UIAlertAction(title: "Import Wallet", style: .default) { _ in
            Coordinator.main.present(scene: .importWallet, from: self, transition: .modal, completion: nil)
        }
        alertController.addAction(importWalletAction)
        let cancelAction = UIAlertAction(title: L10n.Common.Button.cancel, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.barButtonItem = sender
        }
        present(alertController, animated: true, completion: nil)
    }
    
}

