//
//  RedPacketRecipientSelectViewController.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 11/7/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxSwiftUtilities
import Web3

protocol RedPacketRecipientSelectViewControllerDelegate: class {
    func redPacketRecipientSelectViewController(_ viewController: RedPacketRecipientSelectViewController, didSelect contactInfo: FullContactInfo)
    func redPacketRecipientSelectViewController(_ viewController: RedPacketRecipientSelectViewController, didDeselect contactInfo: FullContactInfo)
}

class RedPacketRecipientSelectViewController: UIViewController {
    
    private let titleLabelHeight: CGFloat = 42
    private let tableViewHeight: CGFloat = 122
    
    weak var delegate: RedPacketRecipientSelectViewControllerDelegate?
    weak var optionFieldView: OptionFieldView?
    
    let disposedBag = DisposeBag()
    
    // Input
    var redPacketProperty: RedPacketProperty!
    private let searchText = BehaviorRelay<String>(value: "")
    var contacts: [FullContactInfo] = []
    
    private lazy var finishBarButtonItem = UIBarButtonItem(title: "Finish", style: .done, target: self, action: #selector(RedPacketRecipientSelectViewController.finishBarButtonItemDidPressed(_:)))
    
    private var titleLabelView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor(hex: 0xD1D3D9)
        view.addShadow(ofColor: UIColor(hex: 0xDDDDDD)!, radius: 0, offset: CGSize(width: 0, height: 1), opacity: 1)
        return view
    }()
    
    private var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = L10n.Keyboard.Label.selectRecipients
        label.font = FontFamily.SFProDisplay.medium.font(size: 16)
        return label
    }()
    
    var recipientInputView: KeyboardInputView = {
        let inputView = KeyboardInputView(frame: .zero)
        return inputView
    }()
    
    private let titleDividerView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .gray
        return view
    }()
    
    private var recipientsTableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.setEditing(true, animated: false)
        
        return tableView
    }()
    
}

extension RedPacketRecipientSelectViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configNavBar()
        configUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateNavigationItem()
    }
    
}

extension RedPacketRecipientSelectViewController {
    
    @objc
    private func finishBarButtonItemDidPressed(_ sender: UIBarButtonItem) {
        let viewController = CreatedRedPacketViewController()
        viewController.viewModel = CreatedRedPacketViewModel(redPacketProperty: redPacketProperty)
        navigationController?.pushViewController(viewController, animated: true)
    }
    
}

extension RedPacketRecipientSelectViewController {
    
    private func configNavBar() {
        title = "Select Recipients"
        navigationItem.rightBarButtonItem = finishBarButtonItem
    }
    
    private func configUI() {
        view.backgroundColor = UIColor._tertiarySystemGroupedBackground
        
        #if TARGET_IS_EXTENSION
        titleLabelView.addSubview(titleLabel)
        titleLabelView.addSubview(recipientInputView)
        recipientInputView.inputTextField.textFieldIsSelected = true
        recipientInputView.inputTextField.customDelegate = self
        
        view.addSubview(titleLabelView)
        view.bringSubviewToFront(titleLabelView)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.equalToSuperview().dividedBy(2.0)
        }
        
        recipientInputView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
            make.leading.equalTo(titleLabel.snp.trailing)
        }
        
        titleLabelView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.view.layoutMarginsGuide)
            make.height.equalTo(titleLabelHeight)
        }
        #endif
        
        view.addSubview(recipientsTableView)
        recipientsTableView.snp.makeConstraints { make in
            #if TARGET_IS_EXTENSION
            make.top.equalTo(titleLabelView.snp.bottom)
            #else
            make.top.equalToSuperview()
            #endif
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        // Setup recipientsTableView
        recipientsTableView.delegate = self
        recipientsTableView.dataSource = self
        
        bindData()
    }
    
    private func bindData() {
        searchText.asObservable()
            .map { [weak self] searchString -> [FullContactInfo]? in
                let allContacts = Contact.all()
                return self?.filterAvailableContacts(allContacts, searchText: searchString)
            }
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] filteredContactInfos in
                self?.contacts = filteredContactInfos ?? []
                self?.recipientsTableView.reloadData()
            })
            .disposed(by: disposedBag)
    }
    
    private func filterAvailableContacts(_ allContacts: [Contact], searchText: String) -> [FullContactInfo] {
        let allFullContactInfo = allContacts.compactMap { contact -> FullContactInfo in
            let emails = contact.getEmails()
            let keys = contact.getKeys()
            return FullContactInfo(contact: contact, emails: emails, keys: keys)
        }
        let searchedData = searchText.isEmpty ? allFullContactInfo : allFullContactInfo.filter { contactInfo -> Bool in
            return contactInfo.contact.name.contains(searchText, caseSensitive: false) || contactInfo.emails.first?.address.contains(searchText, caseSensitive: false) ?? false
        }
        return searchedData
    }

    func reloadRecipients() {
        // Make searchText send signal as trigger
        searchText.accept(searchText.value)
    }
    
}

extension RedPacketRecipientSelectViewController {
    
    // FIXME: works only when table view not filter data
    private func updateNavigationItem() {
        guard let selectedRows = recipientsTableView.indexPathsForSelectedRows else {
            finishBarButtonItem.isEnabled = false
            return
        }
        
        finishBarButtonItem.isEnabled = !selectedRows.isEmpty
    }
    
}

extension RedPacketRecipientSelectViewController: ReceipientTextFieldDelegate {
    
    func receipientTextField(_ textField: ReceipientTextField, textDidChange text: String?) {
        let searchCrit = text ?? ""
        searchText.accept(searchCrit)
    }
    
}

extension RedPacketRecipientSelectViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecipientCellTableViewCell.identifier, for: indexPath) as! RecipientCellTableViewCell
        cell.selectedBackgroundView = UIView()
        cell.contactInfo = contacts[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.redPacketRecipientSelectViewController(self, didSelect: contacts[indexPath.row])
        updateNavigationItem()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        delegate?.redPacketRecipientSelectViewController(self, didDeselect: contacts[indexPath.row])
        updateNavigationItem()
    }
}
