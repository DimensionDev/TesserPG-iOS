//
//  RedPacketRecipientSelectViewController.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 11/7/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol RedPacketRecipientSelectViewControllerDelegate: class {
    func redPacketRecipientSelectViewController(_ viewController: RedPacketRecipientSelectViewController, didSelect contactInfo: FullContactInfo)
    func redPacketRecipientSelectViewController(_ viewController: RedPacketRecipientSelectViewController, didDeselect contactInfo: FullContactInfo)
}

class RedPacketRecipientSelectViewController: UIViewController {
    
    private let titleLabelHeight: CGFloat = 42
    private let tableViewHeight: CGFloat = 122
    
    private let searchText = BehaviorRelay<String>(value: "")
    private let disposedBag = DisposeBag()
    
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
    
    var recipientInputView: RecipientInputView = {
        let inputView = RecipientInputView(frame: .zero)
        
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
        tableView.register(UINib(nibName: RecipientCellTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: RecipientCellTableViewCell.identifier)
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.setEditing(true, animated: false)
        
        return tableView
    }()
    
    weak var delegate: RedPacketRecipientSelectViewControllerDelegate?
    
    var contacts: [FullContactInfo] = []
    
    weak var optionFieldView: OptionFieldView?

    override func viewDidLoad() {
        super.viewDidLoad()

        configNavBar()
        configUI()
    }


    private func configNavBar() {
        title = "Select Recipients"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .plain, target: self, action: #selector(createRedPacketButtonDidClicked))
    }
    
    @objc
    private func createRedPacketButtonDidClicked() {

    }
    
    private func configUI() {
        view.backgroundColor = UIColor._tertiarySystemGroupedBackground
        titleLabelView.addSubview(titleLabel)
        
        titleLabelView.addSubview(recipientInputView)
        recipientInputView.inputTextField.textFieldIsSelected = true
        recipientInputView.inputTextField.customDelegate = self
        recipientsTableView.delegate = self
        recipientsTableView.dataSource = self
        
        view.addSubview(titleLabelView)
        view.addSubview(recipientsTableView)
        
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
        
        recipientsTableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(titleLabelView.snp.bottom)
            make.bottom.equalToSuperview()
        }
        
//        resultLabel.snp.makeConstraints { make in
//            make.leading.trailing.equalToSuperview()
//            make.top.equalTo(recipientsTableView.snp.bottom).offset(16)
//        }
        
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
        
//        let filteredData = allFullContactInfo.filter({ (contactInfo) -> Bool in
//            if let selectedData = self.optionFieldView?.selectedContacts {
//                return !selectedData.contains {
//                    return $0.contact.id == contactInfo.contact.id
//                }
//            }
//            return true
//        })
//        if searchText.isEmpty {
//            return filteredData
//        } else {
//            return filteredData.filter { contactInfo -> Bool in
//                return contactInfo.contact.name.contains(searchText, caseSensitive: false) || contactInfo.emails.first?.address.contains(searchText, caseSensitive: false) ?? false
//            }
//        }
    }
    
    private func isContactSelected(_ contact: FullContactInfo) -> Bool {
        guard let selectedContacts = self.optionFieldView?.selectedContacts else {
            return false
        }
        return selectedContacts.contains(contact)
    }

    func reloadRecipients() {
            // Make searchText send signal as trigger
            searchText.accept(searchText.value)
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
//        return recipients.count
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecipientCellTableViewCell.identifier, for: indexPath) as! RecipientCellTableViewCell
        cell.selectedBackgroundView = UIView()
        cell.contactInfo = contacts[indexPath.row]
        cell.setSelected(isContactSelected(contacts[indexPath.row]), animated: false)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.redPacketRecipientSelectViewController(self, didSelect: contacts[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        delegate?.redPacketRecipientSelectViewController(self, didDeselect: contacts[indexPath.row])
    }
}
