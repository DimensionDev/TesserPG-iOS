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

final class RedPacketRecipientSelectViewModel {
    
    let disposeBag = DisposeBag()
    
    // Input
    
    // Output
    let isDeploying: Driver<Bool>
    let contractAddress = BehaviorRelay<EthereumData?>(value: nil)
    let message = BehaviorRelay<Swift.Result<Message, WalletService.Error>?>(value: nil)
    
    init() {
        let activityIndicator = ActivityIndicator()
        isDeploying = activityIndicator.asDriver()
    
//            .drive(onNext: { redPacketProperty in
//                guard let redPacketProperty = redPacketProperty else {
//                    self.message.accept(nil)
//                    return
//                }
//
//
//
//            })
//            .disposed(by: disposeBag)
    }
    
    func deployRedPacketContract(for redPacketProperty: RedPacketProperty) {
        Observable.just(redPacketProperty)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .observeOn(MainScheduler.asyncInstance)
            .flatMapLatest { redPacketProperty -> Observable<RedPacketProperty> in
                do {
                    try WalletService.validate(redPacketProperty: redPacketProperty)
                    return Observable.just(redPacketProperty)
                } catch {
                    return Observable.error(error)
                }
            }
            .flatMapLatest { redPacketProperty -> Observable<EthereumData> in
                os_log("%{public}s[%{public}ld], %{public}s: delopy RP contract for wallet %s", ((#file as NSString).lastPathComponent), #line, #function, redPacketProperty.walletModel!.address)
                let walletAddress = try! EthereumAddress(hex: redPacketProperty.walletModel!.address, eip55: false)
                return WalletService.getTransactionCount(address: walletAddress)
                    .flatMap { nonce -> Single<EthereumData> in
                        return WalletService.delopyRedPacket(for: redPacketProperty, nonce: nonce)
                }
                .flatMap { transactionHash -> Single<EthereumData> in
                    // TODO: add record to database
                    
                    return WalletService.getContractAddress(transactionHash: transactionHash)
                        .retryWhen({ error -> Observable<Int> in
                            return error.enumerated().flatMap({ index, element -> Observable<Int> in
                                // retry every 3.0 sec
                                return Observable.timer(10.0, scheduler: MainScheduler.instance)
                            })
                        })
                }
                .asObservable()
            }
            .subscribe(onNext: { contractAddress in
                os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, contractAddress.hex())
            }, onError: { error in
                os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
}

protocol RedPacketRecipientSelectViewControllerDelegate: class {
    func redPacketRecipientSelectViewController(_ viewController: RedPacketRecipientSelectViewController, didSelect contactInfo: FullContactInfo)
    func redPacketRecipientSelectViewController(_ viewController: RedPacketRecipientSelectViewController, didDeselect contactInfo: FullContactInfo)
}

class RedPacketRecipientSelectViewController: UIViewController {
    
    private let titleLabelHeight: CGFloat = 42
    private let tableViewHeight: CGFloat = 122
    
    private let disposedBag = DisposeBag()
    let viewModel = RedPacketRecipientSelectViewModel()
    
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
    weak var optionFieldView: OptionFieldView?
    
    // Input
    var redPacketProperty: RedPacketProperty!
    private let searchText = BehaviorRelay<String>(value: "")
    var contacts: [FullContactInfo] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        configNavBar()
        configUI()
    }

    private func configNavBar() {
        title = "Select Recipients"
        navigationItem.rightBarButtonItem = finishBarButtonItem
    }
    
    @objc
    private func finishBarButtonItemDidPressed(_ sender: UIBarButtonItem) {
        viewModel.deployRedPacketContract(for: redPacketProperty)
        
        // let viewController = CreatedRedPacketViewController()
        // navigationController?.pushViewController(viewController, animated: true)
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
        
//        resultLabel.snp.makeConstraints { make in
//            make.leading.trailing.equalToSuperview()
//            make.top.equalTo(recipientsTableView.snp.bottom).offset(16)
//        }
        
        // Setup recipientsTableView
        recipientsTableView.delegate = self
        recipientsTableView.dataSource = self
        
        bindData()
        updateNavigationItem()
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
    
//    private func isContactSelected(_ contact: FullContactInfo) -> Bool {
//        guard let selectedContacts = self.optionFieldView?.selectedContacts else {
//            return false
//        }
//        return selectedContacts.contains(contact)
//    }

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
//        return recipients.count
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecipientCellTableViewCell.identifier, for: indexPath) as! RecipientCellTableViewCell
        cell.selectedBackgroundView = UIView()
        cell.contactInfo = contacts[indexPath.row]
        // cell.setSelected(isContactSelected(contacts[indexPath.row]), animated: false)
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
