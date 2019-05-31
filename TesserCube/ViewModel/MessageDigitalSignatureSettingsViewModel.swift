//
//  MessageDigitalSignatureSettingsViewModel.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-5-16.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class MessageDigitalSignatureSettingsViewModel: NSObject {

    let settings = MessageDigitalSignatureSettings.allCases

    // Input
    let messageDigitalSignatureSetting: BehaviorRelay<MessageDigitalSignatureSettings>

    init(messageDigitalSignatureSetting: MessageDigitalSignatureSettings) {
        self.messageDigitalSignatureSetting = BehaviorRelay(value: messageDigitalSignatureSetting)
    }

}

// MARK: - UITableViewDataSource
extension MessageDigitalSignatureSettingsViewModel: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }

    // swiftlint:disable force_cast
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let type = settings[indexPath.row]
        let reuseIdentifier = type.rawValue
        let cell: SettingsTableViewCell = (tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ?? SettingsTableViewCell(style: .default, reuseIdentifier: reuseIdentifier)) as! SettingsTableViewCell

        switch type {
        case .automatic:
            cell.textLabel?.text = L10n.SettingsViewController.Settings.MessageDigitalSignature.Automatic.long
        case .doNotSignMessages:
            cell.textLabel?.text = L10n.SettingsViewController.Settings.MessageDigitalSignature.NotSign.long
        }

        messageDigitalSignatureSetting.asDriver()
            .drive(onNext: { setting in
                cell.accessoryType = type == setting ? .checkmark : .none
            })
            .disposed(by: cell.disposeBag)
        cell.selectionStyle = .none

        return cell
    }
    // swiftlint:enable force_cast

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:     return " "
        default:    return nil
        }
    }
    
}
