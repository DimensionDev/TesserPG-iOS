//
//  SettingsViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-5-15.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit

class SettingsViewController: TCBaseViewController {

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        tableView.tableFooterView = UIView()
        return tableView
    }()

    let viewModel = SettingsViewModel()

    override func configUI() {
        super.configUI()

        title = L10n.SettingsViewController.title
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.dataSource = viewModel
        tableView.delegate = self
    }

}

extension SettingsViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView.indexPathForSelectedRow.flatMap { indexPath in
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

// MARK: - UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let setting = viewModel.settings[indexPath.section][indexPath.row]
        switch setting {
        case .messageDigitalSignature:
            let messageDigitalSignatureSettingsViewModel = MessageDigitalSignatureSettingsViewModel(messageDigitalSignatureSetting: viewModel.messageDigitalSignatureSetting.value)
            Coordinator.main.present(scene: Coordinator.Scene.messageDigitalSignatureSettings(viewModel: messageDigitalSignatureSettingsViewModel, delegate: self), from: self)
        default:
            break
        }
    }

}

// MARK: - MessageDigitalSignatureSettingsViewControllerDelegate
extension SettingsViewController: MessageDigitalSignatureSettingsViewControllerDelegate {

    func messageDigitalSignatureSettingsViewController(_ controller: MessageDigitalSignatureSettingsViewController, didSelectMessageDigitalSignatureSettings setting: MessageDigitalSignatureSettings) {
        viewModel.messageDigitalSignatureSetting.accept(setting)
    }

}
