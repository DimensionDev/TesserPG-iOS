//
//  MessageDigitalSignatureSettingsViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-5-15.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

protocol MessageDigitalSignatureSettingsViewControllerDelegate: class {
    func messageDigitalSignatureSettingsViewController(_ controller: MessageDigitalSignatureSettingsViewController, didSelectMessageDigitalSignatureSettings setting: MessageDigitalSignatureSettings)
}

class MessageDigitalSignatureSettingsViewController: TCBaseViewController {

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        tableView.tableFooterView = UIView()
        tableView.cellLayoutMarginsFollowReadableWidth = true
        return tableView
    }()

    weak var delegate: MessageDigitalSignatureSettingsViewControllerDelegate?

    override func configUI() {
        super.configUI()

        title = L10n.SettingsViewController.Settings.messageDigitalSignature

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.top.bottom.equalToSuperview()
        }

        tableView.dataSource = viewModel
        tableView.delegate = self
    }

    var viewModel: MessageDigitalSignatureSettingsViewModel!

}

// MARK: - UITableViewDelegate
extension MessageDigitalSignatureSettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let setting = viewModel.settings[indexPath.row]
        viewModel.messageDigitalSignatureSetting.accept(setting)
        delegate?.messageDigitalSignatureSettingsViewController(self, didSelectMessageDigitalSignatureSettings: setting)
    }

}
