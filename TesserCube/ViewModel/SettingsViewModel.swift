//
//  SettingsViewModel.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-5-15.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class SettingsViewModel: NSObject {

    let disposeBag = DisposeBag()

    enum SettingType: String, CaseIterable {
        case messageDigitalSignature
        case showLowercaseKeys
    }

    let settings: [[SettingType]] = [
        [
            .messageDigitalSignature,
            .showLowercaseKeys
        ]
    ]

    // Input
    let messageDigitalSignatureSetting = BehaviorRelay(value: KeyboardPreference.kMessageDigitalSignatureSettings)
    let showLowercaseKeys = BehaviorRelay(value: KeyboardPreference.kSmallLowercase)

    override init() {
        messageDigitalSignatureSetting.asDriver()
            .drive(onNext: { setting in
                KeyboardPreference.kMessageDigitalSignatureSettings = setting
            })
            .disposed(by: disposeBag)

        showLowercaseKeys.asDriver()
            .drive(onNext: { isOn in
                KeyboardPreference.kSmallLowercase = isOn
            })
            .disposed(by: disposeBag)
    }

}

// MARK: - UITableViewDataSource
extension SettingsViewModel: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return settings.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings[section].count
    }

    // swiftlint:disable force_cast
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let type = settings[indexPath.section][indexPath.row]
        let reuseIdentifier = type.rawValue
        switch type {
        case .messageDigitalSignature:
            let cell: SettingsTableViewCell = (tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ?? SettingsTableViewCell(style: .value1, reuseIdentifier: reuseIdentifier)) as! SettingsTableViewCell
            cell.textLabel?.text = L10n.SettingsViewController.Settings.messageDigitalSignature
            messageDigitalSignatureSetting.asDriver()
                .map { settings -> String in
                    switch settings {
                    case .automatic:         return L10n.SettingsViewController.Settings.MessageDigitalSignature.Automatic.short
                    case .doNotSignMessages: return L10n.SettingsViewController.Settings.MessageDigitalSignature.NotSign.short
                    }
                }
                .drive(cell.detailTextLabel!.rx.text)
                .disposed(by: cell.disposeBag)
            cell.accessoryType = .disclosureIndicator
            return cell
        case .showLowercaseKeys:
            let cell: SettingsTableViewCell = (tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ?? SettingsTableViewCell(style: .default, reuseIdentifier: reuseIdentifier)) as! SettingsTableViewCell
            cell.textLabel?.text = L10n.SettingsViewController.Settings.showLowercaseKeys
            cell.selectionStyle = .none
            cell.accessoryView = {
                let switcher = UISwitch()
                switcher.isOn = showLowercaseKeys.value
                switcher.rx.isOn.asDriver()
                    .drive(showLowercaseKeys)
                    .disposed(by: cell.disposeBag)
                return switcher
            }()
            return cell
        }
    }
    // swiftlint:enable force_cast

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:     return L10n.SettingsViewController.TableView.Header.keyboard
        default:    return nil
        }
    }

}
