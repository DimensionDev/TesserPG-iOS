//
//  RecommendRecipientsView.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/2/26.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol RecommendRecipientsViewDelegate: class {
    func recommendRecipientsView(_ view: RecommendRecipientsView, didSelect contactInfo: FullContactInfo)
}

class RecommendRecipientsView: UIView, Thematic {
    
    private let titleLabelHeight: CGFloat = 42
    private let tableViewHeight: CGFloat = 122
    
    var recommendContacts: [FullContactInfo] = [] {
        didSet {
            if recommendContacts.count == 0 {
                resultLabel.text = L10n.Keyboard.Label.noContactsFound
            } else if recommendContacts.count == 1 {
                resultLabel.text = L10n.Keyboard.Label.oneContactFound
            } else {
                resultLabel.text = L10n.Keyboard.Label.pluralContactFound(recommendContacts.count)
            }

            let emptySearchText = recipientInputView.inputTextField.text?.isEmpty ?? false
            resultLabel.isHidden = emptySearchText
        }
    }
    
    weak var delegate: RecommendRecipientsViewDelegate?
    weak var optionFieldView: OptionFieldView?
    
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
        tableView.register(UINib(nibName: RecipientCellTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: RecipientCellTableViewCell.identifier)
        return tableView
    }()
    
    private var resultLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = FontFamily.SFProDisplay.regular.font(size: 14)
        label.textColor = .lightGray
        label.textAlignment = .center
        label.text = L10n.Keyboard.Label.noContactsFound
        label.isHidden = true
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configUI()
    }
    
    private func configUI() {
        backgroundColor = UIColor(hex: 0xF0F0F0)
        titleLabelView.addSubview(titleLabel)
        
        titleLabelView.addSubview(recipientInputView)
        recipientInputView.inputTextField.textFieldIsSelected = true
        recipientInputView.inputTextField.customDelegate = self
        recipientsTableView.delegate = self
        recipientsTableView.dataSource = self
        
        addSubview(titleLabelView)
        addSubview(recipientsTableView)
        addSubview(resultLabel)
        
        bringSubviewToFront(titleLabelView)
        
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
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(titleLabelHeight)
        }
        
        recipientsTableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(titleLabelView.snp.bottom)
            make.bottom.equalToSuperview()
        }
        
        resultLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(recipientsTableView.snp.bottom).offset(16)
        }
        
        bindData()
    }

    // TODO: color
    func updateColor(theme: Theme) {
        switch theme {
        case .light:
            backgroundColor = UIColor(hex: 0xF0F0F0)
            titleLabelView.backgroundColor = UIColor(hex: 0xD1D3D9)
            titleLabelView.addShadow(ofColor: UIColor(hex: 0xDDDDDD)!, radius: 0, offset: CGSize(width: 0, height: 1), opacity: 1)
            titleLabel.textColor = .black
        case .dark:
            backgroundColor = .keyboardCharKeyBackgroundDark
            titleLabelView.backgroundColor = .keyboardFuncKeyBackgroundDark
            titleLabelView.addShadow(ofColor: .keyboardBackgroundDark, radius: 0, offset: CGSize(width: 0, height: 1), opacity: 1)
            titleLabel.textColor = .white
        }
    }
    
    private func bindData() {
        searchText.asObservable()
            .map { [weak self] searchString -> [FullContactInfo]? in
                let allContacts = Contact.all()
                return self?.filterAvailableContacts(allContacts, searchText: searchString)
            }
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] filteredContactInfos in
                self?.recommendContacts = filteredContactInfos ?? []
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
        let filteredData = allFullContactInfo.filter({ (contactInfo) -> Bool in
            if let selectedData = self.optionFieldView?.selectedContacts {
                return !selectedData.contains {
                    return $0.contact.id == contactInfo.contact.id
                }
            }
            return true
        })
        if searchText.isEmpty {
            return filteredData
        } else {
            return filteredData.filter { contactInfo -> Bool in
                return contactInfo.contact.name.contains(searchText, caseSensitive: false) || contactInfo.emails.first?.address.contains(searchText, caseSensitive: false) ?? false
            }
        }
    }
    
//    lazy var searchForRecipients: (String) -> Void = {
//        return debounce(delay: .milliseconds(100), queue: DispatchQueue.global()) { input in
//            var filteredData = [Account]()
//            if input.isEmpty {
//                filteredData = DataHandler.getMockData()
//            } else {
//                let searchedData = DataHandler.getMockData().filter { account -> Bool in
//                    return account.username.contains(input, caseSensitive: false) || account.address.contains(input, caseSensitive: false) || account.serial.contains(input, caseSensitive: false)
//                }
//                filteredData = searchedData.filter({ (account) -> Bool in
//                    if let selectedData = self.optionFieldView?.selectedRecipients {
//                        return !selectedData.contains {
//                            return $0.serial == account.serial
//                        }
//                    }
//                    return true
//                })
//            }
//            DispatchQueue.main.async { [weak self] in
//                self?.recipients = filteredData
//                self?.recipientsTableView.reloadData()
//            }
//        }
//    }()
    
    func reloadRecipients() {
        // Make searchText send signal as trigger
        searchText.accept(searchText.value)
//        searchForRecipients(recipientInputView.inputTextField.text ?? "")
    }
}

extension RecommendRecipientsView: ReceipientTextFieldDelegate {
    
    func receipientTextField(_ textField: ReceipientTextField, textDidChange text: String?) {
        let searchCrit = text ?? ""
//        searchForRecipients(searchCrit)
        searchText.accept(searchCrit)
    }
    
}

extension RecommendRecipientsView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return recipients.count
        return recommendContacts.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecipientCellTableViewCell.identifier, for: indexPath) as! RecipientCellTableViewCell
        cell.contactInfo = recommendContacts[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.recommendRecipientsView(self, didSelect: recommendContacts[indexPath.row])
        searchText.accept(searchText.value)
    }
}
