//
//  SignViewController.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 12/19/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol SignViewControllerDelegate: class {
    func signViewController(_ viewController: SignViewController, didClick sendBarButton: UIBarButtonItem)
}

class SignViewController: UIViewController, TCkeyboardModeProvider {
    
    let disposBag = DisposeBag()
    
    var contentString = BehaviorRelay<String>(value: "")
    
    weak var delegate: SignViewControllerDelegate?
    
    var mode: TCKeyboardMode {
        return .sign
    }
    
    static var extraHeight: CGFloat {
        return 200
    }
    
    var contentInputView: KeyboardInputView = {
        let inputView = KeyboardInputView(frame: .zero)
        inputView.layer.masksToBounds = true
        inputView.layer.cornerRadius = 10
        return inputView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNaviItems()
        
        delegate = KeyboardModeManager.shared
        
        contentInputView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentInputView)
        NSLayoutConstraint.activate([
            contentInputView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            contentInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            contentInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            contentInputView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6),
        ])
        
        contentInputView.inputTextField.textFieldIsSelected = true
        contentInputView.inputTextField.customDelegate = self
        
        contentString.asDriver()
            .map { !$0.isEmpty }
            .drive(navigationItem.rightBarButtonItem!.rx.isEnabled)
            .disposed(by: disposBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        contentInputView.inputTextField.textFieldIsSelected = true
        contentInputView.inputTextField.customDelegate = self
    }
    
    private func setupNaviItems() {
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: L10n.Keyboard.Encrypt.sendEncryptedMessageButton, style: .done, target: self, action: #selector(sendBarButtonDidClicked(_:)))
    }
    
    @objc
    private func sendBarButtonDidClicked(_ sender: UIBarButtonItem) {
        delegate?.signViewController(self, didClick: sender)
    }
}

extension SignViewController: ReceipientTextFieldDelegate {
    func receipientTextField(_ textField: ReceipientTextField, textDidChange text: String?) {
        contentString.accept(text ?? "")
    }
}
