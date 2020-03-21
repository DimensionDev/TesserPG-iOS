//
//  PasteKeyViewController.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/20.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import RxCocoa
import RxSwift
import ConsolePrint

class PasteKeyViewController: TCBaseViewController {
    
    var needPassphrase: Bool = false
    var armoredKey: String?
    
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
        button.color = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.setTitle(L10n.MeViewController.Action.Button.importKey, for: .normal)
        return button
    }()
    
    private func createSeparator() -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .separator
        return view
    }
    
    override func configUI() {
        super.configUI()

        title = needPassphrase ? L10n.PasteKeyViewController.Title.pastePrivateKey : L10n.PasteKeyViewController.Title.importPublicKey

        navigationItem.largeTitleDisplayMode = .never
        if navigationItem.leftBarButtonItem == nil {
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

        if let armoredKey = armoredKey {
            keyTextView.text = armoredKey
        } else if hasValidKeyInPasteboard(), keyTextView.text.isEmpty {
            keyTextView.text = UIPasteboard.general.string
            // showPasteboardConfirmAlert()
        }

    }
    
    private func hasValidKeyInPasteboard() -> Bool {
        if UIPasteboard.general.hasStrings, let pasteString = UIPasteboard.general.string, KeyFactory.isValidMessage(from: pasteString) {
            return true
        }

        return false
    }
    
    private func showPasteboardConfirmAlert() {
        
    }
    
    deinit {
        consolePrint("deinit")
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
        
        // Check public key block
        guard let publicKeyBlock = KeyFactory.extractPublicKeyBlock(from: keyString) else {
            let title = L10n.Common.Alert.error
            let message = L10n.PasteKeyViewController.Alert.Message.noPublicKey
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: L10n.Common.Button.ok, style: .default) { _ in
                // do nothing
            }
            alertController.addAction(okAction)
            
            present(alertController, animated: true, completion: nil)
            return
        }
        
        let privateKeyBlock = KeyFactory.extractSecretKeyBlock(from: keyString)
        let passphrase = needPassphrase ? passwordTextField.text : nil
        
        switch needPassphrase {
        case false where privateKeyBlock != nil:
            // alert user continue importing will only import the public part of keypair
            let title = L10n.PasteKeyViewController.Alert.Title.notice
            let message = L10n.PasteKeyViewController.Alert.Message.importAsPublicKey
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            let continueAction = UIAlertAction(title: L10n.PasteKeyViewController.Alert.Button.continue, style: .default) { [weak self] _ in
                self?.importKey(armoredKey: publicKeyBlock, passphrase: passphrase)
            }
            alertController.addAction(continueAction)
            
            let cancelAction = UIAlertAction(title: L10n.Common.Button.cancel, style: .cancel) { _ in
                // Do nothing
            }
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
            
        case false:
            // import public key
            importKey(armoredKey: publicKeyBlock, passphrase: passphrase)

        case true where privateKeyBlock == nil:
            // alert user can not find private key block
            let error = DMSPGPError.invalidPrivateKey
            showSimpleAlert(title: L10n.Common.Alert.error, message: error.localizedDescription)
                
        case true:
            // import private key
            importKey(armoredKey: keyString, passphrase: passphrase)
        }
    }
    
    func importKey(armoredKey: String, passphrase: String?) {
        showHUD(L10n.Common.Hud.importingKey)
        ProfileService.default.decryptKey(armoredKey: armoredKey, passphrase: passphrase) { [weak self] (tckey, error) in
            guard let `self` = self else { return }
            self.hideHUD()
            
            if let error = error {
                self.showSimpleAlert(title: L10n.Common.Alert.error, message: error.localizedDescription)
            } else {
                guard let tckey = tckey else {
                    fatalError()
                }
                
                if self.needPassphrase && tckey.entities.count != 1 {
                    let title = L10n.Common.Alert.error
                    let message = L10n.TCError.PGPKeyErrorReason.notSupportAddMultiplePrivateKey
                    self.showSimpleAlert(title: title, message: message)
                    return
                }
                
                Coordinator.main.present(scene: .importKeyConfirm(key: tckey, passphrase: passphrase), from: self)
            }
        }
    }

}
