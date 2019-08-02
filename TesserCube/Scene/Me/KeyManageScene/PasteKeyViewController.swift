//
//  PasteKeyViewController.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/20.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import DMSOpenPGP
import SnapKit
import SwifterSwift
import RxCocoa
import RxSwift
import ConsolePrint

class PasteKeyViewController: TCBaseViewController {
    
    var needPassphrase: Bool = false
    
    let disposeBag = DisposeBag()
    
    private lazy var keyTextView: UITextView = {
        let textView = UITextView(frame: .zero)
        textView.font = FontFamily.SFProText.regular.font(size: 17)
        textView.backgroundColor = .clear
        return textView
    }()
    
    private lazy var passwordTextField: UITextField = {
        let textField = UITextField(frame: .zero)
        textField.isSecureTextEntry = true
        textField.placeholder = L10n.PasteKeyViewController.Placeholder.password
        return textField
    }()
    
    private lazy var importButton: TCActionButton = {
        let button = TCActionButton(frame: .zero)
        button.color = Asset.sketchBlue.color
        button.setTitleColor(.white, for: .normal)
        button.setTitle(L10n.MeViewController.Action.Button.importKey, for: .normal)
        return button
    }()
    
    private func createSeparator() -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = Asset.separator.color
        return view
    }
    
    override func configUI() {
        super.configUI()

        title = needPassphrase ? L10n.PasteKeyViewController.Title.pastePrivateKey : L10n.PasteKeyViewController.Title.importPublicKey

        navigationItem.largeTitleDisplayMode = .never
        if !needPassphrase {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: L10n.Common.Button.cancel, style: .plain, target: self, action: #selector(PasteKeyViewController.cancelBarButtonItemPressed(_:)))
        }

        let separator1 = createSeparator()
        let separator2 = createSeparator()
        let separator3 = createSeparator()
        view.addSubview(separator1)
        view.addSubview(keyTextView)
        
        if needPassphrase {
            view.addSubview(separator2)
            view.addSubview(passwordTextField)
            
            separator2.snp.makeConstraints { maker in
                maker.leading.trailing.equalTo(view.layoutMarginsGuide)
                maker.height.equalTo(1)
                maker.top.equalTo(keyTextView.snp.bottom)
            }
            
            passwordTextField.snp.makeConstraints { maker in
                maker.leading.trailing.equalTo(view.layoutMarginsGuide)
                maker.top.equalTo(separator2.snp.bottom)
                maker.height.equalTo(44)
            }
        }
        
        view.addSubview(separator3)
        view.addSubview(importButton)
        
        separator1.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(view.layoutMarginsGuide)
            maker.height.equalTo(1)
            maker.top.equalTo(view.safeAreaLayoutGuide).offset(20)
        }
        
        keyTextView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(view.layoutMarginsGuide)
            maker.top.equalTo(separator1.snp.bottom)
            maker.height.equalTo(176)
        }
        
        separator3.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(view.layoutMarginsGuide)
            maker.height.equalTo(1)
            if needPassphrase {
                maker.top.equalTo(passwordTextField.snp.bottom)
            } else {
                maker.top.equalTo(keyTextView.snp.bottom)
            }
        }
        
        importButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(view.layoutMarginsGuide)
            maker.top.equalTo(separator3.snp.bottom).offset(10)
        }
        
        importButton.addTarget(self, action: #selector(importKeyButtonDidClicked(_:)), for: .touchUpInside)
        
        keyTextView.rx.text
            .orEmpty.map { !$0.isEmpty }
            .bind(to: importButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        #if STUB
//        keyTextView.text = {
//            let date = Date()
//            let formatter = DateFormatter()
//            formatter.dateFormat = "'Test'yyyyMMddHHmm"
//            let name = formatter.string(from: date)
//            let key = KeyGenerator().generate(for: "\(name) <tesser@cube.com>", passphrase: "Tessercube")
//            let armored: String = {
//                guard let data = try? key.export() else {
//                    return ""
//                }
//                if needPassphrase {
//                    let pri = Armor.armored(data, as: .secretKey)
//                    let pub = Armor.armored(data, as: .publicKey)
//                    return [pri, pub].joined(separator: "")
//                } else {
//                    // Warning: should export to .public else Armord string contains private key info
//                    guard let data = try? key.export(keyType: .public) else {
//                        return ""
//                    }
//                    return Armor.armored(data, as: .publicKey)
//                }
//
//            }()
//            return armored
//        }()
//
//        if needPassphrase {
//            passwordTextField.text = "Tessercube"
//        }
        #else
        if hasValidKeyInPasteboard(), keyTextView.text.isEmpty {
            keyTextView.text = UIPasteboard.general.string
            //            showPasteboardConfirmAlert()
        }
        #endif
    }
    
    private func hasValidKeyInPasteboard() -> Bool {
        if UIPasteboard.general.hasStrings, let pasteString = UIPasteboard.general.string,
        let _ = try? DMSPGPKeyRing(armoredKey: pasteString) {
            return true
        }
        return false
    }
    
    private func showPasteboardConfirmAlert() {
        
    }
    
    deinit {
        print("")
    }
}

private extension PasteKeyViewController {

    @objc func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func importKeyButtonDidClicked(_ sender: UIButton) {
        guard let keyString = keyTextView.text else {
            return
        }
        showHUD(L10n.Common.Hud.importingKey)
        let passphrase = needPassphrase ? passwordTextField.text : nil
        ProfileService.default.decryptKey(armoredKey: keyString, passphrase: passphrase) { [weak self] (tckey, error) in
            DispatchQueue.main.async {
                self?.hideHUD()
                if let error = error {
                    self?.showSimpleAlert(title: L10n.Common.Alert.error, message: error.localizedDescription)
                } else {
                    Coordinator.main.present(scene: .importKeyConfirm(key: tckey!, passphrase: passphrase), from: self)
                }
            }
        }
//        Coordinator.main.present(scene: .importKeyConfirm, from: self)
//        return
//        guard let keyString = keyTextView.text else {
//            return
//        }
//        showHUD(L10n.Common.Hud.importingKey)
//        let passphrase = needPassphrase ? passwordTextField.text : nil
//        ProfileService.default.addNewKey(armoredKey: keyString, passphrase: passphrase) { [weak self] error in
//            DispatchQueue.main.async {
//                self?.hideHUD()
//                if let error = error {
//                    self?.showSimpleAlert(title: L10n.Common.Alert.error, message: error.localizedDescription)
//                } else {
//                    self?.dismiss(animated: true, completion: nil)
//                }
//            }
//        }   // end addNewKeys
    }

}
