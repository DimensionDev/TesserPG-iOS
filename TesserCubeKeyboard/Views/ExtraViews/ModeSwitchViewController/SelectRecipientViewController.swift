//
//  SelectRecipientViewController.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 12/18/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class SelectRecipientViewController: UIViewController {
    
    var selectRecipientView: RecommendRecipientsView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.Keyboard.Label.selectRecipients
        
        selectRecipientView = RecommendRecipientsView(frame: .zero)
        selectRecipientView?.updateColor(theme: KeyboardModeManager.shared.currentTheme)
        selectRecipientView?.delegate = KeyboardModeManager.shared
        selectRecipientView?.optionFieldView = KeyboardModeManager.shared.optionsView
        
        selectRecipientView?.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(selectRecipientView!)
        NSLayoutConstraint.activate([
            selectRecipientView!.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            selectRecipientView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            selectRecipientView!.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            selectRecipientView!.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "", style: .done, target: self, action: #selector(sendBarButtonDidClicked(_:)))
    }
    
    @objc
    private func sendBarButtonDidClicked(_ sender: UIBarButtonItem) {
        
    }
}
