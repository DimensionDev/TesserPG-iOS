//
//  SelectRecipientViewController.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 12/18/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

protocol SelectRecipientViewControllerDelegate: class {
    func selectRecipientViewController(_ viewController: SelectRecipientViewController, rawMessage: String, didClick sendBarButton: UIBarButtonItem)
}

class SelectRecipientViewController: UIViewController {
    
    var rawMessage: String?
    
    var selectRecipientView: RecommendRecipientsView?
    
    weak var delegate: SelectRecipientViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.Keyboard.Label.selectRecipients
        
        delegate = KeyboardModeManager.shared
        
        selectRecipientView = RecommendRecipientsView(frame: .zero)
        selectRecipientView?.updateColor(theme: KeyboardModeManager.shared.currentTheme)
        selectRecipientView?.delegate = KeyboardModeManager.shared
        selectRecipientView?.optionFieldView = KeyboardModeManager.shared.optionsView
        
        KeyboardModeManager.shared.optionsView?.suggestionView?.isHidden = true
        KeyboardModeManager.shared.optionsView?.selectedRecipientsView?.isHidden = false
        
        selectRecipientView?.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(selectRecipientView!)
        NSLayoutConstraint.activate([
            selectRecipientView!.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            selectRecipientView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            selectRecipientView!.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            selectRecipientView!.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: L10n.Keyboard.Encrypt.sendEncryptedMessageButton, style: .done, target: self, action: #selector(sendBarButtonDidClicked(_:)))
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectRecipientView?.recipientInputView.inputTextField.textFieldIsSelected = true
        selectRecipientView?.reloadRecipients()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        KeyboardModeManager.shared.optionsView?.suggestionView?.isHidden = false
        KeyboardModeManager.shared.optionsView?.selectedRecipientsView?.isHidden = true
    }
    
    @objc
    private func sendBarButtonDidClicked(_ sender: UIBarButtonItem) {
        guard let message = rawMessage else { return }
        delegate?.selectRecipientViewController(self, rawMessage: message, didClick: sender)
    }
}
