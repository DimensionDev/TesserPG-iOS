//
//  ContactsListViewController.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/18.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol PickContactsDelegate: class {
    func contactsListViewController(_ controller: ContactsListViewController, didSelect contacts: [Contact])
}

class ContactsListViewController: TCBaseViewController {
    
    var viewModel = ContactListViewModel()
    
    var isPickContactMode: Bool = false {
        didSet {
            tableView.isEditing = isPickContactMode
            searchController.hidesNavigationBarDuringPresentation = !isPickContactMode
        }
    }
    
    var preSelectedContacts = [Contact]()
    
    weak var delegate: PickContactsDelegate?
    
    private let disposeBag = DisposeBag()
    
    private var sortedKeys = [String]()
    
    private var groupedUsers = [String: [Contact]]()
    
    private var searchedSortedKeys = [String]()
    
    private var searchedGroupedUsers = [String: [Contact]]()
    
    private var searchText = PublishRelay<String>()
    
    private var sourceSortedKeys: [String] {
        return searchController.isActive ? searchedSortedKeys : sortedKeys
    }
    
    private var sourceGroupedContacts: [String: [Contact]] {
        return searchController.isActive ? searchedGroupedUsers : groupedUsers
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.alwaysBounceVertical = true
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "ContactCell", bundle: nil), forCellReuseIdentifier: String(describing: ContactCell.self))
        if #available(iOS 13.0, *) {
            tableView.backgroundColor = .systemBackground
        } else {
            // Fallback on earlier versions
            tableView.backgroundColor = Asset.sceneBackground.color
        }
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.keyboardDismissMode = .interactive
        tableView.preservesSuperviewLayoutMargins = true
        tableView.cellLayoutMarginsFollowReadableWidth = true
        return tableView
    }()
    
    private lazy var emptyView: ListEmptyView = {
        let view = ListEmptyView(frame: .zero)
        view.textLabel.text = L10n.ContactListViewController.EmptyView.prompt
        return view
    }()
    
    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.obscuresBackgroundDuringPresentation = false
        controller.delegate = self
        // controller.searchBar.delegate = self
        controller.searchResultsUpdater = self

        return controller
    }()

    override func configUI() {
        super.configUI()

        title = L10n.MainTabbarViewController.TabBarItem.Contacts.title

        navigationItem.searchController = searchController
        navigationItem.largeTitleDisplayMode = .automatic
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        setupSearchBar()
        setupBarButtonItems()

        // Add tableView first to avoid navigation bar title not shrink issue
        view.addSubview(tableView)
        addEmptyStateView(emptyView)

        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.top.bottom.equalToSuperview()
        }
        tableView.delegate = self
        tableView.dataSource = self
        
        bindData()
    }
    
    private func setupSearchBar() {
        searchText
            .throttle(0.3, scheduler: MainScheduler.instance)
            .do(onNext: { [weak self] searchText in
                self?.searchContacts(by: searchText)
            })
            .observeOn(MainScheduler.asyncInstance)
            .subscribe({ [weak self] _ in
                guard let `self` = self else { return }
                if self.searchController.isActive {
                    self.tableView.reloadData()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setupBarButtonItems() {
        if isPickContactMode {
            let donePickContactsBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePickContactsDidClicked(_:)))
            navigationItem.rightBarButtonItem = donePickContactsBarButtonItem
        } else {
            let addBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addContactButtonDidClicked(_:)))
            navigationItem.rightBarButtonItem = addBarButtonItem
        }
    }
    
    @objc
    private func addContactButtonDidClicked(_ sender: UIBarButtonItem) {
        #if !TARGET_IS_EXTENSION
        Coordinator.main.present(scene: .pasteKey(armoredKey: nil, needPassphrase: false), from: self, transition: .modal, completion: nil)
        #endif
    }
    
    @objc
    private func donePickContactsDidClicked(_ sender: UIBarButtonItem) {
        if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
            let selectedContacts = selectedIndexPaths.compactMap { (indexPath) -> Contact? in
                let contacts = sourceGroupedContacts[sourceSortedKeys[indexPath.section]]
                return contacts?[indexPath.row]
            }
            delegate?.contactsListViewController(self, didSelect: selectedContacts)
        } else {
            delegate?.contactsListViewController(self, didSelect: [])
        }

        if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    private func bindData() {
        ProfileService.default.contacts
            .bind(to: viewModel.contacts)
            .disposed(by: disposeBag)
        
        viewModel.hasContact
            .drive(onNext: { [weak self] hasContact in
                self?.emptyView.isHidden = hasContact
            })
            .disposed(by: disposeBag)
        
        viewModel.contacts
            .do(onNext: { [weak self] contacts in
                self?.generateSortedKeys(contacts: contacts)
            })
            .observeOn(MainScheduler.asyncInstance)
            .subscribe({ [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }
    
    private func generateSortedKeys(contacts: [Contact]) {
        sortedKeys.removeAll()
        groupedUsers.removeAll()
        let grouped = [String: [Contact]].init(grouping: contacts) { (contact) -> String in
            guard let firstPinyin = contact.name.pinyin.first else {
                return "#"
            }
            if firstPinyin.isLetter {
                return String(firstPinyin).uppercased()
            }
            return "#"
        }
        groupedUsers = grouped.mapValues { (contacts) -> [Contact] in
            return contacts.sorted(by: { (contact1, contact2) -> Bool in
                return contact1.name.pinyin < contact2.name.pinyin
            })
        }
        sortedKeys = groupedUsers.keys.sorted(by: { (value1, value2) -> Bool in
            if value1 == "#" {
                return false
            }
            if value2 == "#" {
                return true
            }
            return value1 < value2
        })
    }
    
    private func searchContacts(by searchText: String) {
        searchedSortedKeys.removeAll()
        searchedGroupedUsers.removeAll()
        let filteredContacts = viewModel.contacts.value.filter { (contact) -> Bool in
            return contact.name.range(of: searchText, options: .caseInsensitive) != nil
        }
        let grouped = [String: [Contact]].init(grouping: filteredContacts) { (contact) -> String in
            guard let firstPinyin = contact.name.pinyin.first else {
                return "#"
            }
            if firstPinyin.isLetter {
                return String(firstPinyin).uppercased()
            }
            return "#"
        }
        searchedGroupedUsers = grouped.mapValues { (contacts) -> [Contact] in
            return contacts.sorted(by: { (contact1, contact2) -> Bool in
                return contact1.name.pinyin < contact2.name.pinyin
            })
        }
        searchedSortedKeys = searchedGroupedUsers.keys.sorted(by: { (value1, value2) -> Bool in
            if value1 == "#" {
                return false
            }
            if value2 == "#" {
                return true
            }
            return value1 < value2
        })
    }
}

extension ContactsListViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)

        if !isPickContactMode {
            tableView.indexPathForSelectedRow.flatMap {
                self.tableView.deselectRow(at: $0, animated: animated)
            }
        }
    }

}

// MARK: - UITableViewDelegate
extension ContactsListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 28
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.font = FontFamily.SFProText.semibold.font(size: 17)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contacts = sourceGroupedContacts[sourceSortedKeys[indexPath.section]]
        guard let contactId = contacts?[indexPath.row].id else {
            return
        }

        if !isPickContactMode {
            #if !TARGET_IS_EXTENSION
            Coordinator.main.present(scene: .contactDetail(contactId: contactId), from: self)
            #endif
        } else {
            viewModel.selectedContactIDs.insert(contactId)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let contacts = sourceGroupedContacts[sourceSortedKeys[indexPath.section]]
        guard let contactId = contacts?[indexPath.row].id else {
            return
        }

        viewModel.selectedContactIDs.remove(contactId)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard isPickContactMode,
        let contacts = sourceGroupedContacts[sourceSortedKeys[indexPath.section]] else {
            return
        }

        if let index = preSelectedContacts.firstIndex(where: { (selectedContact) -> Bool in
            return selectedContact.id == contacts[indexPath.row].id
        }) {
            preSelectedContacts.remove(at: index)
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }

        if indexPath.row < contacts.count, viewModel.selectedContactIDs.contains(contacts[indexPath.row].id ?? -1 ) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let navigationBar = navigationController?.navigationBar,
            emptyView.textLabel.frame != .zero else {
            return
        }

        let emptyViewTextLabelFrameInView = emptyView.convert(emptyView.textLabel.frame, to: view)
        let navigationBarFrameInView = navigationBar.convert(navigationBar.frame, to: view)
        // manually calculate it due to .maxY not return expect value
        let navigationBarFrameMaxY = navigationBar.frame.origin.y + navigationBarFrameInView.height

        if navigationBarFrameMaxY >= emptyViewTextLabelFrameInView.minY {
            let mask = CALayer()
            mask.backgroundColor = UIColor.blue.cgColor
            var maskFrame = emptyView.textLabel.bounds
            maskFrame.origin.y = navigationBarFrameMaxY - emptyViewTextLabelFrameInView.minY
            mask.frame = maskFrame
            emptyView.textLabel.layer.mask = mask
        } else {
            emptyView.textLabel.layer.mask = nil
        }
    }
    
}

// MARK: - UITableViewDataSource
extension ContactsListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sourceSortedKeys[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ContactCell.self), for: indexPath) as! ContactCell
        // swiftlint:enable force_cast
        let contacts = sourceGroupedContacts[sourceSortedKeys[indexPath.section]]
        cell.contact = contacts?[indexPath.row]
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sourceSortedKeys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sourceGroupedContacts[sourceSortedKeys[section]]!.count
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sourceSortedKeys
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
}

// MARK: - UISearchResultsUpdating
extension ContactsListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchText.accept(searchController.searchBar.text ?? "")
    }
}

// MARK: - UISearchControllerDelegate
extension ContactsListViewController: UISearchControllerDelegate {
    func didDismissSearchController(_ searchController: UISearchController) {
        tableView.reloadData()
    }
}
