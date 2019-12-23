//
//  EncryptViewController.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 12/17/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class EncryptViewController: UIViewController, TCkeyboardModeProvider {
    
    let disposBag = DisposeBag()
    
    var contentString = BehaviorRelay<String>(value: "")
    
    var mode: TCKeyboardMode {
        return .encrypt
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
        
        let nextBarButtonItem = UIBarButtonItem(title: L10n.Common.Button.next, style: .plain, target: self, action: #selector(nextBarButtonDidClicked(_:)))
        nextBarButtonItem.isEnabled = false
        navigationItem.rightBarButtonItem = nextBarButtonItem
    }
    
    @objc
    private func nextBarButtonDidClicked(_ sender: UIBarButtonItem) {
        let selectReceipientVC = SelectRecipientViewController()
        selectReceipientVC.rawMessage = contentString.value
        navigationController?.pushViewController(selectReceipientVC, animated: true)
    }
}

extension EncryptViewController: ReceipientTextFieldDelegate {
    func receipientTextField(_ textField: ReceipientTextField, textDidChange text: String?) {
        contentString.accept(text ?? "")
    }
}
