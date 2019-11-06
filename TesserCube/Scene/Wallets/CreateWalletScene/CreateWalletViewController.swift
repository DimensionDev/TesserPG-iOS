//
//  CreateWalletViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-6.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class CreateWalletViewController: TCBaseViewController {

    enum TableViewCellType {
        case passphrase
        case confirmPassphrase
    }

    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(PasswordTextFieldTableViewCell.self, forCellReuseIdentifier: String(describing: PasswordTextFieldTableViewCell.self))
        return tableView
    }()

    let sections: [[TableViewCellType]] = [
       [
           .passphrase,
           .confirmPassphrase,
        ],
    ]

    var createWalletButtonBottomLayoutConstraint: NSLayoutConstraint!
    let createWalletButton: TCActionButton = {
        let button = TCActionButton()
        button.color = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Create Wallet", for: .normal)
        return button
    }()

    override func configUI() {
        super.configUI()

        title = "Create Wallet"
        if #available(iOS 13.0, *) {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(CreateWalletViewController.closeBarButtonItemPressed(_:)))
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(CreateWalletViewController.closeBarButtonItemPressed(_:)))
        }

        // Layout
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Setup tableView
        tableView.dataSource = self

        // Layout Button
        createWalletButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(createWalletButton)

        let createWalletButtonBottomLowPriorityLayoutConstraint = view.bottomAnchor.constraint(greaterThanOrEqualTo: createWalletButton.bottomAnchor, constant: 16)
        createWalletButtonBottomLowPriorityLayoutConstraint.priority = .defaultLow
        createWalletButtonBottomLayoutConstraint = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: createWalletButton.bottomAnchor)
        NSLayoutConstraint.activate([
            createWalletButton.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            createWalletButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            createWalletButtonBottomLowPriorityLayoutConstraint,
            createWalletButtonBottomLayoutConstraint,
        ])

    }

}

extension CreateWalletViewController {

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        // createWalletButtonBottomLayoutConstraint.constant = view.safeAreaInsets.bottom
    }

}

extension CreateWalletViewController {

    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

}

// MARK: - UITableViewDataSource
extension CreateWalletViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section][indexPath.row] {
        case .passphrase:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PasswordTextFieldTableViewCell.self), for: indexPath) as! PasswordTextFieldTableViewCell
            cell.passphraseTextField.placeholder = "Set Password"

            return cell
        case .confirmPassphrase:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PasswordTextFieldTableViewCell.self), for: indexPath) as! PasswordTextFieldTableViewCell
            cell.passphraseTextField.placeholder = "Confirm Password"

            return cell
        }
    }

}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct CreateWalletViewController_Previews: PreviewProvider {
    static var previews: some View {
        NavigationControllerRepresenable(rootViewController: CreateWalletViewController())
    }
}

#endif
