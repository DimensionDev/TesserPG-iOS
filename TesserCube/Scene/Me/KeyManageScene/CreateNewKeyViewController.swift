//
//  CreateNewKeyViewController.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/21.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import Eureka
import SnapKit

class CreateNewKeyViewController: FormViewController {
    
    private let easyModeRowTag = "easyMode"
    
    private let availableCreateKeyOption: [CreateKeyOption] = [.rsa, .ecc]
    
    private let availableCreateKeyLength: [Int] = [3072, 4096]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        title = L10n.MeViewController.Action.Button.createKey

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(CreateNewKeyViewController.cancelBarButtonItemPressed(_:)))
        
        setupFormStyle()
        
        var passwordRules = RuleSet<String>()
//        passwordRules.add(rule: RuleRequired(msg: "Please input password", id: "Password_Required"))
        passwordRules.add(rule: RuleRegExp(regExpr: "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{6,20}$", msg: "Password should be minimum 8 characters at least 1 Alphabet and 1 Number", id: nil))
        
        let footer = createButtonFooter()
        
        form +++ Section() {
            $0.footer = footer
            }
            <<< NameRow("name"){ row in
                row.placeholder = L10n.CreateNewKeyViewController.Label.name
                row.add(rule: RuleRequired(msg: L10n.CreateNewKeyViewController.Alert.Title.nameRequired, id: "Name_Required"))
                row.validationOptions = .validatesOnChange
                }
                .cellUpdate { cell, row in
                    cell.textField.font = FontFamily.SFProText.regular.font(size: 17)
                }
            <<< EmailRow("email") { row in
                row.placeholder = L10n.CreateNewKeyViewController.Label.email
                row.add(rule: RuleRequired(msg: L10n.CreateNewKeyViewController.Alert.Title.emailRequired, id: "Email_Required"))
                row.add(rule: RuleEmail(msg: L10n.CreateNewKeyViewController.Alert.Title.emailInvalid, id: "Email_Invalid"))
                row.validationOptions = .validatesOnChangeAfterBlurred
                }
                .cellUpdate { cell, row in
                    cell.textField.font = FontFamily.SFProText.regular.font(size: 17)
                }
            <<< PasswordRow("Password") { row in
                row.placeholder = L10n.CreateNewKeyViewController.Label.password
//                row.add(ruleSet: passwordRules)
                }.cellUpdate { cell, row in
                    cell.textField.font = FontFamily.SFProText.regular.font(size: 17)
                }
            <<< PasswordRow() { row in
                row.placeholder = L10n.CreateNewKeyViewController.Label.confirmPassword
                row.add(rule: RuleEqualsToRow(form: form, tag: "Password", msg: L10n.CreateNewKeyViewController.Alert.Title.passwordNotMatch, id: nil))
                }.cellUpdate { cell, row in
                    cell.textField.font = FontFamily.SFProText.regular.font(size: 17)
                }
            <<< SwitchRow("easyMode") { row in
                row.cellProvider = CellProvider<SwitchCell>(nibName: "SwitchCell", bundle: Bundle.main)
                row.cell.height = { 43 }
                row.title = L10n.CreateNewKeyViewController.Label.easymode
                row.cell.textLabel?.isHidden = true
                if let textField = row.cell.viewWithTag(66) as? UILabel {
                    textField.text = row.title
                }
                if let switchWidget = row.cell.viewWithTag(77) as? UISwitch {
                    row.cell.switchControl = switchWidget
                }
                row.value = true
                }
            <<< PickerInlineRow<CreateKeyOption>("Algorithm") { (row : PickerInlineRow<CreateKeyOption>) -> Void in
                row.title = L10n.CreateNewKeyViewController.Label.algorithm
                row.displayValueFor = { (rowValue: CreateKeyOption?) in
                    return rowValue?.displayName ?? ""
                }
                row.options = availableCreateKeyOption
                row.value = row.options[0]
                row.hidden = .function([easyModeRowTag], { form -> Bool in
                    let row: RowOf<Bool>! = form.rowBy(tag: self.easyModeRowTag)
                    return row.value ?? true == true
                })
            }
            <<< PickerInlineRow<Int>("KeyLength") { (row : PickerInlineRow<Int>) -> Void in
                row.title = L10n.CreateNewKeyViewController.Label.keyLength
                
                row.displayValueFor = { (rowValue: Int?) in
                    return "\(rowValue ?? 0)"
                }
                
                row.options = availableCreateKeyLength
                row.value = availableCreateKeyLength[0]
                
                row.hidden = .function([easyModeRowTag, "Algorithm"], { form -> Bool in
                    let algorithmRow: RowOf<CreateKeyOption>! = form.rowBy(tag: "Algorithm")
                    let easyModeRow: RowOf<Bool>! = form.rowBy(tag: self.easyModeRowTag)
                    let selectedAlgorithm = algorithmRow.value ?? .rsa
                    return (easyModeRow.value ?? true == true) || selectedAlgorithm != .rsa
                })
        }
        
    }
    
    private func setupFormStyle() {
        
        LabelRow.defaultCellUpdate = { cell, row in
            cell.detailTextLabel?.textColor = .red
            cell.detailTextLabel?.font = FontFamily.SFProText.regular.font(size: 13)
            cell.detailTextLabel?.numberOfLines = 0

        }
    }
    
    private func createButtonFooter() -> HeaderFooterView<UIView> {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 110))
        view.preservesSuperviewLayoutMargins = true

        let button = TCActionButton(frame: .zero)
        button.color = Asset.sketchBlue.color
        button.setTitleColor(.white, for: .normal)
        button.setTitle(L10n.MeViewController.Action.Button.createKey, for: .normal)
        view.addSubview(button)
        
        button.snp.makeConstraints({ maker in
            maker.leading.trailing.equalTo(view.layoutMarginsGuide)
            maker.top.equalToSuperview().offset(30)
        })
        button.addTarget(self, action: #selector(createKeyButtonDidClicked(_:)), for: .touchUpInside)
        
        var header = HeaderFooterView<UIView>(.callback({
            return view
        }))
        header.height = { 110 }
        return header
    }
    
    @objc
    private func createKeyButtonDidClicked(_ sender: UIButton) {
        let validationErrors = form.validate()
        guard validationErrors.isEmpty else {
            let alertVC = UIAlertController(title: nil, message: validationErrors.first?.msg, preferredStyle: .alert)
            alertVC.addAction(title: L10n.Common.Button.ok)
            present(alertVC, animated: true)
            return
        }
        let valuesDictionary = form.values()
        guard let email = valuesDictionary["email"] as? String, let name = valuesDictionary["name"] as? String else {
            let alertVC = UIAlertController(title: nil, message: validationErrors.first?.msg, preferredStyle: .alert)
            alertVC.addAction(title: L10n.Common.Button.ok)
            present(alertVC, animated: true)
            return
        }
        showHUD(L10n.Common.Hud.creatingKey)
        
        let userID = DMSPGPUserIDTranslator.buildUserID(name: name, email: email, comment: nil)
        let password = valuesDictionary["Password"] as? String
        
        let chosenKeyLength: Int = (valuesDictionary["KeyLength"] as? Int) ?? 3072
        let generateKeyOption: CreateKeyOption = (valuesDictionary["Algorithm"] as? CreateKeyOption) ?? .rsa
        
        let generateKeyData = GenerateKeyData(name: name, email: email, password: password, masterKey: KeyData(strength: chosenKeyLength, algorithm: generateKeyOption.dmsPGPPublicKeyAlgorithm, curve: generateKeyOption.curve), subkey: KeyData(strength: chosenKeyLength, algorithm: generateKeyOption.dmsSubkeyAlgorithm, curve: generateKeyOption.curve))
        
        ProfileService.default.addNewKey(userID: userID, passphrase: password, generateKeyData: generateKeyData) { [weak self] error in
            DispatchQueue.main.async {
                self?.hideHUD()
                if let error = error {
                    self?.showSimpleAlert(title: L10n.Common.Alert.error, message: error.localizedDescription)
                } else {
                    self?.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    deinit {
        print("")
    }
}

private extension CreateNewKeyViewController {

    @objc func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

}
