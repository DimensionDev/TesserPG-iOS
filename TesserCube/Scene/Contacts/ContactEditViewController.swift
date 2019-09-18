//
//  ContactEditViewController.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/28.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit

class ContactEditViewController: TCBaseViewController {
    
    enum ContactEditType: CaseIterable {
        case name
        case email
        case trust
        
        var prompt: String {
            switch self {
            case .name:
                return L10n.EditContactViewController.EditType.name
            case .email:
                return L10n.ContactDetailViewController.Label.email.capitalized
            case .trust:
                return L10n.EditContactViewController.EditType.trust
            }
        }
    }
    
    var contactId: Int64
    
    private var contact: Contact?
    
    private var keys: [TCKey] = []
    
    private var emails: [Email] = []
    
    private lazy var editTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.alwaysBounceVertical = true
        tableView.tableFooterView = UIView()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.preservesSuperviewLayoutMargins = true
        tableView.cellLayoutMarginsFollowReadableWidth = true
        return tableView
    }()
    
    init(contactId: Int64) {
        self.contactId = contactId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func configUI() {
        super.configUI()
        navigationItem.largeTitleDisplayMode = .never
        setupNavigationItems()
        
        view.addSubview(editTableView)
        editTableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        
        editTableView.register(nibWithCellClass: ContactEditTextCell.self)
        editTableView.dataSource = self
        editTableView.delegate = self
        
        bindData()
    }
    
    private func setupNavigationItems() {
        let doneEditBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneEditBarButtonDidClicked(_:)))
        navigationItem.rightBarButtonItem = doneEditBarButtonItem
    }
    
    @objc
    private func doneEditBarButtonDidClicked(_ sender: UIBarButtonItem) {
        guard let nameCell = editTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ContactEditTextCell, let newName = nameCell.inputTextField.text else {
            return
        }
        let newEmail = (editTableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? ContactEditTextCell)?.inputTextField.text ?? ""
        do {
            var email = emails.first
            email?.address = newEmail
            try contact?.update(name: newName, email: email)
            
            navigationController?.popViewController(animated: true)
        } catch let error {
            showHUDError("Fail to edit the contact")
        }
    }
    
    private func bindData() {
        contact = Contact.find(id: contactId)
        
        keys = contact?.getKeys() ?? []
        emails = contact?.getEmails() ?? []
        editTableView.reloadData()
    }
    
    @objc
    private func deleteButtonDidClicked(_ sender: UIButton) {
        let alertVC = UIAlertController(title: nil, message: L10n.EditContactViewController.Action.Button.confirmDeleteContact, preferredStyle: .actionSheet)
        alertVC.addAction(title: L10n.Common.Button.delete, style: .destructive, isEnabled: true) { _ in
            self.checkContactKeys(sender)
        }
        alertVC.addAction(title: L10n.Common.Button.cancel, style: .cancel, isEnabled: true)
        if let presenter = alertVC.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.frame
        }
        self.present(alertVC, animated: true)
    }
    
    private func checkContactKeys(_ sender: UIButton) {
        var hasSecretKey = false
        if let keys = contact?.getKeys() {
            for key in keys where key.hasSecretKey {
                hasSecretKey = true
                break
            }
        }
        if hasSecretKey {
            let alertVC = UIAlertController(title: nil, message: L10n.EditContactViewController.Action.Button.confirmDeleteKeypairs, preferredStyle: .actionSheet)
            alertVC.addAction(UIAlertAction(title: L10n.EditContactViewController.Action.Button.keepPublicKey, style: .default, handler: { _ in
                self.doDeleteContact(keepPublicKey: true)
            }))
            alertVC.addAction(UIAlertAction(title: L10n.EditContactViewController.Action.Button.deleteKeyPair, style: .default, handler: { _ in
                self.doDeleteContact(keepPublicKey: false)
            }))
            alertVC.addAction(title: L10n.Common.Button.cancel, style: .cancel, isEnabled: true)
            if let presenter = alertVC.popoverPresentationController {
                presenter.sourceView = sender
                presenter.sourceRect = sender.frame
            }

            self.present(alertVC, animated: true)
        } else {
            doDeleteContact(keepPublicKey: false)
        }
    }
    
    private func doDeleteContact(keepPublicKey: Bool) {
        do {
            guard let toDeleteContact = contact else { return }
            if keepPublicKey {
                try ProfileService.default.deleteContactSecretKey(toDeleteContact)
            } else {
                try ProfileService.default.deleteContact(toDeleteContact)
            }
            navigationController?.popToRootViewController(animated: true)
        } catch let error {
            showHUDError("Fail to delete the contact")
        }
    }
}

extension ContactEditViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ContactEditTextCell {
            cell.inputTextField.becomeFirstResponder()
        }
    }
}

extension ContactEditViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withClass: ContactEditTextCell.self, for: indexPath)
            cell.titleLabel.text = ContactEditType.allCases[indexPath.row].prompt
            let editType = ContactEditType.allCases[indexPath.row]
            switch editType {
            case .name:
                cell.inputTextField.text = contact?.name
            case .email:
                cell.inputTextField.text = emails.first?.address
                cell.inputTextField.textType = .emailAddress
            case .trust:
                cell.inputTextField.text = "true"
            }
            cell.selectionStyle = .none

            // Note: It's should automatically adopting dark mode due to cell.traitCollection is .dark
            // However it's still light mode. Mannully set color as workaround. (Xcode 11 Beta 5)
            if #available(iOS 13.0, *) {
                cell.contentView.backgroundColor = .secondarySystemBackground
                cell.titleLabel.textColor = .secondaryLabel
                cell.inputTextField.textColor = .label
            } else {
                // Fallback on earlier versions
                cell.contentView.backgroundColor = .white
                cell.titleLabel.textColor = .lightGray
                cell.inputTextField.textColor = .black
            }
            return cell
        } else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "deleteButton")
            let deleteButton = UIButton(type: .system)
            deleteButton.setTitleColor(.systemRed, for: .normal)
            deleteButton.setTitle(L10n.EditContactViewController.Label.deleteContact, for: .normal)
            cell.contentView.addSubview(deleteButton)
            deleteButton.addTarget(self, action: #selector(deleteButtonDidClicked(_:)), for: .touchUpInside)
            deleteButton.snp.makeConstraints { maker in
                maker.leading.trailing.equalTo(cell.contentView.layoutMarginsGuide)
                maker.center.equalToSuperview()
                maker.height.equalTo(44)
            }
            cell.selectionStyle = .none
            return cell
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
}
