//
//  MessagesViewController.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/22.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import UIKit
import SwifterSwift
import SnapKit
import RxCocoa
import RxSwift
import ConsolePrint

class MessagesViewController: TCBaseViewController {

    let disposeBag = DisposeBag()
    let viewModel = MessagesViewModel()

    // Safe area bottom inset without keyboard
    private var defaultSafeAreaBottomInset: CGFloat = 0

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.obscuresBackgroundDuringPresentation = false
        controller.delegate = self
        controller.searchBar.delegate = self
        controller.searchResultsUpdater = self
        // controller.searchBar.scopeButtonTitles = viewModel.segmentedControlItems

        return controller
    }()
    private lazy var emptyView: ListEmptyView = {
        let view = ListEmptyView(title: L10n.MessagesViewController.EmptyView.prompt)
        return view
    }()
    private(set) lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: viewModel.segmentedControlItems)
        segmentedControl.selectedSegmentIndex = 0
        return segmentedControl
    }()
    private lazy var tableHeaderView: UIView = {
        let headerView = UIView()

        if #available(iOS 13.0, *) {
            // iOS 13 changed the navigation bar bottom hairline appearance
            // so only add tool bar in iOS 12 and previous
        } else {
            let toolbar = UIToolbar()
            toolbar.translatesAutoresizingMaskIntoConstraints = false
            toolbar.delegate = self

            headerView.addSubview(toolbar)
            toolbar.snp.makeConstraints { maker in
                maker.top.equalTo(headerView.snp.top)
                maker.leading.trailing.equalTo(headerView)
                maker.bottom.equalTo(headerView.snp.bottom)
            }
        }
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { maker in
            maker.top.equalTo(headerView.snp.top).offset(10).priority(.high)
            maker.leading.trailing.equalTo(headerView.layoutMarginsGuide).priority(.high)
            maker.bottom.equalTo(headerView.snp.bottom).offset(-10).priority(.high)
        }

        return headerView
    }()

    // toolbar
    private lazy var selectBarButtonItem: UIBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(MessagesViewController.selectBarButtonItemPressed(_:)))
    private lazy var deleteBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: L10n.Common.Button.delete, style: .plain, target: self, action: #selector(MessagesViewController.deleteBarButtonItemPressed(_:)))
        item.tintColor = .systemRed
        return item
    }()
    private lazy var tableViewEditToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        let items = [selectBarButtonItem,
                     UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                     deleteBarButtonItem]
        toolbar.setItems(items, animated: false)
        return toolbar
    }()
    private var tableViewEditToolbarConstraints = [NSLayoutConstraint]()

    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.alwaysBounceVertical = true
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 220
        tableView.register(MessageCardCell.self, forCellReuseIdentifier: String(describing: MessageCardCell.self))
        tableView.register(RedPacketCardTableViewCell.self, forCellReuseIdentifier: String(describing: RedPacketCardTableViewCell.self))
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .interactive
        tableView.preservesSuperviewLayoutMargins = true
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.allowsMultipleSelectionDuringEditing = true
        return tableView
    }()

    private lazy var bottomActionsView: UIStackView = {
        let stackView = UIStackView(frame: .zero)
        stackView.spacing = 12
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .fill
        return stackView
    }()

    override func configUI() {
        super.configUI()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: L10n.Common.Button.edit, style: .plain, target: self, action: #selector(MessagesViewController.editBarButtonItemPressed(_:)))
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true

        view.addSubview(tableView)
        view.addSubview(bottomActionsView)
        addEmptyStateView(emptyView)
        view.backgroundColor = ._systemBackground

        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.top.bottom.equalToSuperview()
        }

        bottomActionsView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(view.readableContentGuide)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).offset(-15)
        }

        tableView.delegate = self
        if #available(iOS 13.0, *) {
            viewModel.configureDataSource(tableView: tableView)
            tableView.dataSource = viewModel.diffableDataSource
        } else {
            tableView.dataSource = viewModel
        }
        tableView.tableHeaderView = tableHeaderView

        reloadActionsView()

        if let tabBar = tabBarController?.tabBar {
            tableViewEditToolbar.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(tableViewEditToolbar)
            tableViewEditToolbarConstraints.append(contentsOf: [
                tableViewEditToolbar.topAnchor.constraint(equalTo: tabBar.topAnchor),
                tableViewEditToolbar.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
                tableViewEditToolbar.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
                tableViewEditToolbar.bottomAnchor.constraint(equalTo: tabBar.layoutMarginsGuide.bottomAnchor),
            ])  // active in viewDidAppear

            tableViewEditToolbar.delegate = self
        } else {
            assertionFailure()
        }

        // Bind data
        ProfileService.default.messages
            .bind(to: viewModel._messages)
            .disposed(by: disposeBag)

        segmentedControl.rx.selectedSegmentIndex
            .bind(to: viewModel.selectedSegmentIndex)
            .disposed(by: disposeBag)

        searchController.searchBar.rx.text.orEmpty
            .throttle(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(viewModel.searchText)
            .disposed(by: disposeBag)

        viewModel.hasMessages
            .drive(emptyView.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.isSearching
            .drive(onNext: { [weak self] isSearching in
                self?.emptyView.textLabel.text = isSearching ? L10n.MessagesViewController.EmptyView.searchingPrompt : L10n.MessagesViewController.EmptyView.prompt
            })
            .disposed(by: disposeBag)

        viewModel.isEditing.asDriver().debug()
            .drive(onNext: { [weak self] isEditing in
                guard let `self` = self else { return }
                self.tableView.setEditing(isEditing, animated: true)
                self.segmentedControl.isEnabled = !isEditing
                self.searchController.searchBar.isUserInteractionEnabled = !isEditing

                self.tabBarController?.tabBar.isUserInteractionEnabled = !isEditing
                self.bottomActionsView.isUserInteractionEnabled = !isEditing
                UIView.animate(withDuration: 0.3, animations: {
                    self.tabBarController?.tabBar.alpha = isEditing ? 0 : 1
                    self.bottomActionsView.alpha = isEditing ? 0 : 1
                })

                self.view.setNeedsLayout()
            })
            .disposed(by: disposeBag)

        // EditBarButtonItem
        if let editBarButtonItem = navigationItem.rightBarButtonItem {
            viewModel.editBarButtonItemTitle.asDriver()
                .drive(editBarButtonItem.rx.title)
                .disposed(by: disposeBag)
            viewModel.editBarButtonItemIsEnable.asDriver()
                .drive(editBarButtonItem.rx.isEnabled)
                .disposed(by: disposeBag)
        }

        // Toolbar
        viewModel.selectBarButtonItemTitle.asDriver()
            .drive(selectBarButtonItem.rx.title)
            .disposed(by: disposeBag)
        viewModel.deleteBarButtonItemIsEnable.asDriver()
            .drive(deleteBarButtonItem.rx.isEnabled)
            .disposed(by: disposeBag)
        viewModel.selectAction.asDriver(onErrorJustReturn: UIBarButtonItem())
            .withLatestFrom(viewModel.selectType.asDriver())
            .drive(onNext: { [weak self] selectType in
                switch selectType {
                case .selectAll:
                    guard let totalRows = self?.tableView.numberOfRows(inSection: 0) else {
                        return
                    }

                    var selectIndexPaths: [IndexPath] = []
                    for i in 0..<totalRows {
                        let indexPath = IndexPath(row: i, section: 0)
                        selectIndexPaths.append(indexPath)
                        self?.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                    }
                    self?.viewModel.selectIndexPaths.accept(selectIndexPaths)

                case .deselectAll:
                    if let rows = self?.tableView.indexPathsForSelectedRows {
                        for row in rows {
                            self?.tableView.deselectRow(at: row, animated: true)
                        }
                    }
                    self?.viewModel.selectIndexPaths.accept([])

                }
            })
            .disposed(by: disposeBag)
        viewModel.deleteAction.asDriver(onErrorJustReturn: UIBarButtonItem())
            .debounce(0.3)
            .withLatestFrom(viewModel.selectIndexPaths.asDriver())
            .drive(onNext: { [weak self] indexPaths in
                guard let `self` = self else { return }

                let message = indexPaths.count == 1 ? L10n.MessagesViewController.Alert.Message.deleteMessage : L10n.MessagesViewController.Alert.Message.deleteMessages(indexPaths.count)
                let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
                if let popoverPresentationController = alertController.popoverPresentationController {
                    popoverPresentationController.barButtonItem = self.deleteBarButtonItem
                }

                let deleteAction = UIAlertAction(title: L10n.Common.Button.delete, style: .destructive) { _ in
                    self.viewModel.isEditing.accept(false)
                    let messages = indexPaths.map { self.viewModel.messages.value[$0.row] }
                    ProfileService.default.delete(messages: messages)
                }
                alertController.addAction(deleteAction)
                let cancelAction = UIAlertAction(title: L10n.Common.Button.cancel, style: .cancel) { _ in
                    // do nothing
                }
                alertController.addAction(cancelAction)

                self.present(alertController, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)

        NotificationCenter.default.addObserver(self, selector: #selector(MessagesViewController.keyboardWillShowNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MessagesViewController.keyboardWillHideNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        viewModel.selectedMessageType.asDriver().debug().drive().disposed(by: disposeBag)
        viewModel.searchText.asDriver().debug().drive().disposed(by: disposeBag)
        
        
        // Update tableView when red packet update
        viewModel.redPacketNotificationToken = RedPacketService.shared.realm?.objects(RedPacket.self).observe { [weak self] change in
            guard let `self` = self else { return }
            os_log("%{public}s[%{public}ld], %{public}s update tableView for red packet", ((#file as NSString).lastPathComponent), #line, #function)
            if #available(iOS 13.0, *) {
                guard let dataSource = self.viewModel.diffableDataSource as? UITableViewDiffableDataSource<MessagesViewModel.Section, Message> else {
                    assertionFailure()
                    return
                }
                
                var snapsot = NSDiffableDataSourceSnapshot<MessagesViewModel.Section, Message>()
                snapsot.appendSections([.main])
                snapsot.appendItems(self.viewModel.messages.value)
                dataSource.apply(snapsot)
                
            } else {
                // clear cache data when data source changed
                self.viewModel.messageExpandedDict = [:]
                self.viewModel.messageMaxNumberOfLinesDict = [:]
                self.tableView.reloadData()
            }
        }
    }

    private func reloadActionsView() {

        bottomActionsView.arrangedSubviews.forEach {
            bottomActionsView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        var actionViews = [UIView]()

        let composeButton = TCActionButton(frame: .zero)
        composeButton.color = .systemBlue
        composeButton.setTitleColor(.white, for: .normal)
        composeButton.setTitle(L10n.MessagesViewController.Action.Button.compose, for: .normal)
        composeButton.addTarget(self, action: #selector(MessagesViewController.composeButtonPressed(_:)), for: .touchUpInside)

        let interpretButton = TCActionButton(frame: .zero)
        interpretButton.color = .systemBlue
        interpretButton.setTitleColor(.white, for: .normal)
        interpretButton.setTitle(L10n.MessagesViewController.Action.Button.interpret, for: .normal)
        interpretButton.addTarget(self, action: #selector(MessagesViewController.interpretButtonPressed(_:)), for: .touchUpInside)

        let bottomStackView = UIStackView(arrangedSubviews: [composeButton, interpretButton], axis: .horizontal, spacing: 15, alignment: .fill, distribution: .fillEqually)

        actionViews.append(bottomStackView)

        bottomActionsView.addArrangedSubviews(actionViews)

        view.layoutIfNeeded()
    }
}

extension MessagesViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.setNeedsLayout()
        self.tableView.layoutIfNeeded()

        // reload data source when table view set right frame
        viewModel.messageExpandedDict = [:]
        viewModel.messageMaxNumberOfLinesDict = [:]
        self.tableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.messages.asDriver()
            .drive(onNext: { [weak self] messages in
                if #available(iOS 13.0, *) {
                    guard let dataSource = self?.viewModel.diffableDataSource as? UITableViewDiffableDataSource<MessagesViewModel.Section, Message> else {
                        assertionFailure()
                        return
                    }

                    var snapsot = NSDiffableDataSourceSnapshot<MessagesViewModel.Section, Message>()
                    snapsot.appendSections([.main])
                    snapsot.appendItems(messages)
                    dataSource.apply(snapsot)

                } else {
                    // clear cache data when data source changed
                    self?.viewModel.messageExpandedDict = [:]
                    self?.viewModel.messageMaxNumberOfLinesDict = [:]
                    self?.tableView.reloadData()
                }
            })
            .disposed(by: disposeBag)

        NSLayoutConstraint.activate(tableViewEditToolbarConstraints)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let headerView = tableView.tableHeaderView else { return }
        let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height
            tableView.tableHeaderView = headerView
            tableView.layoutIfNeeded()
        }

        tableView.contentInset.bottom = viewModel.isEditing.value ? 0 : bottomActionsView.height + 15
    }

}

private extension MessagesViewController {

    @objc private func selectBarButtonItemPressed(_ sender: UIBarButtonItem) {
        viewModel.selectAction.accept(sender)
    }

    @objc private func deleteBarButtonItemPressed(_ sender: UIBarButtonItem) {
        viewModel.deleteAction.accept(sender)
    }

    @objc func editBarButtonItemPressed(_ sender: UIBarButtonItem) {
        viewModel.isEditing.accept(!viewModel.isEditing.value)
    }

    @objc func composeButtonPressed(_ sender: UIButton) {
        Coordinator.main.present(scene: .composeMessage, from: self, transition: .modal, completion: nil)
    }

    @objc func interpretButtonPressed(_ sender: UIButton) {
        Coordinator.main.present(scene: .interpretMessage, from: self, transition: .modal, completion: nil)
    }

}

// MARK: - UITableViewDelegate
extension MessagesViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20 - MessageCardCell.cardVerticalMargin
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20 - MessageCardCell.cardVerticalMargin
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }

        if !tableView.isEditing {
            let actions = viewModel.tableView(tableView, presentingViewController: self, actionsforRowAt: indexPath, isContextMenu: false)
            let alertController: UIAlertController = {
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                let alertActions = actions.map { $0.alertAction }
                for alertAction in alertActions {
                    alertController.addAction(alertAction)
                }
                return alertController
            }()

            if let presenter = alertController.popoverPresentationController {
                presenter.sourceView = cell
                presenter.sourceRect = cell.bounds
            }

            DispatchQueue.main.async {
                self.present(alertController, animated: true, completion: nil)
            }
        } else {
            viewModel.selectIndexPaths.accept(viewModel.selectIndexPaths.value + [indexPath])
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            var selectIndexPaths = viewModel.selectIndexPaths.value
            selectIndexPaths.removeAll(where: { $0 == indexPath })
            viewModel.selectIndexPaths.accept(selectIndexPaths)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard !tableView.isEditing else {
            return nil
        }

        let message = viewModel.messages.value[indexPath.row]
        guard let cell = tableView.cellForRow(at: indexPath) as? MessageCardCell,
        let id = message.id else {
            return nil
        }

        // collapse cell before display context menu
        if viewModel.messageExpandedIDDict[id] == true {
            self.messageCardCell(cell, expandButtonPressed: cell.expandButton)
        }

        let actions = viewModel.tableView(tableView, presentingViewController: self, actionsforRowAt: indexPath, isContextMenu: true)
        let children = actions.compactMap { $0.menuElement }

        return UIContextMenuConfiguration(
            identifier: indexPath as NSCopying,
            previewProvider: nil,
            actionProvider: { _ in
                return UIMenu(title: "", image: nil, identifier: nil, options: [], children: children)
            })
    }

    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
        let cell = tableView.cellForRow(at: indexPath) as? MessageCardCell else {
            return nil
        }

        let center = CGPoint(x: cell.bounds.midX, y: cell.bounds.midY)
        let previewTarget = UIPreviewTarget(container: cell, center: center)
        return UITargetedPreview(view: cell.cardView, parameters: UIPreviewParameters(), target: previewTarget)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? MessageCardCell else { return }

        cell.delegate = self
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return tableView.isEditing
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return UISwipeActionsConfiguration()
    }

    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.clipsToBounds = false
        cell?.contentView.clipsToBounds = false
        cell?.contentView.superview?.clipsToBounds = false
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let headerView = tableView.tableHeaderView else {
            return
        }
        let headerViewFrameInView = headerView.convert(headerView.frame, to: view)
        let emptyViewTextLabelFrameInView = emptyView.convert(emptyView.textLabel.frame, to: view)

        if headerViewFrameInView.maxY >= emptyViewTextLabelFrameInView.minY {
            let mask = CALayer()
            mask.backgroundColor = UIColor.blue.cgColor
            var maskFrame = emptyView.textLabel.bounds
            maskFrame.origin.y = headerViewFrameInView.maxY - emptyViewTextLabelFrameInView.minY
            mask.frame = maskFrame
            emptyView.textLabel.layer.mask = mask
        } else {
            emptyView.textLabel.layer.mask = nil
        }
    }

}

// MARK: - UIToolbarDelegate
extension MessagesViewController: UIToolbarDelegate {

    func position(for bar: UIBarPositioning) -> UIBarPosition {
        if bar === tableViewEditToolbar {
            return .bottom
        } else {
            return .topAttached     // in segment control
        }
    }

}

// MARK: - UISearchControllerDelegate
extension MessagesViewController: UISearchControllerDelegate {

}

// MARK: - UISearchBarDelegate
extension MessagesViewController: UISearchBarDelegate {

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.searchText.accept("")     // reset search text when cancel searching
    }

}

// MARK: - UISearchResultsUpdating
extension MessagesViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        consolePrint(searchController)
    }

}

extension MessagesViewController {

    @objc private func keyboardWillShowNotification(_ notification: Notification) {
//         consolePrint(notification)
        guard let endFrame = notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? CGRect else {
            return
        }
//
//        // consolePrint(endFrame)
        // Keyboard only display in search mode
        tableView.contentInset.bottom = endFrame.height - (tabBarController?.tabBar.size.height ?? 0.0)
        tableView.scrollIndicatorInsets.bottom = endFrame.height - (tabBarController?.tabBar.size.height ?? 0.0)
    }
//
    @objc private func keyboardWillHideNotification(_ notification: Notification) {
        // back to normal mode
        tableView.contentInset.bottom = bottomActionsView.height + 15
        tableView.scrollIndicatorInsets.bottom = 0
    }

}

// MARK: - MessageCardCellDelegate
extension MessagesViewController: MessageCardCellDelegate {

    func messageCardCell(_ cell: MessageCardCell, expandButtonPressed: UIButton) {
        if #available(iOS 13.0, *) {
            guard let dataSource = viewModel.diffableDataSource as? UITableViewDiffableDataSource<MessagesViewModel.Section, Message> else {
                return
            }

            guard let indexPath = tableView.indexPath(for: cell),
            let message = dataSource.itemIdentifier(for: indexPath),
            let id = message.id else {
                return
            }

            guard let isExpand = viewModel.messageExpandedIDDict[id],
            let maxNumberOfLines = viewModel.messageMaxNumberOfLinesIDDict[id] else {
                return
            }

            cell.messageLabel.numberOfLines = isExpand ? 4 : 0
            viewModel.messageExpandedIDDict[id] = !isExpand
            let title = !isExpand ? L10n.MessageCardCell.Button.Expand.collapse : L10n.MessageCardCell.Button.Expand.expand(maxNumberOfLines)
            cell.expandButton.setTitle(title, for: .normal)

            tableView.beginUpdates()
            tableView.endUpdates()

            tableView.scrollToRow(at: indexPath, at: .top, animated: true)

        } else {
            guard let indexPath = tableView.indexPath(for: cell),
            let isExpand = viewModel.messageExpandedDict[indexPath],
            let maxNumberOfLines = viewModel.messageMaxNumberOfLinesDict[indexPath] else {
                return
            }

            cell.messageLabel.numberOfLines = isExpand ? 4 : 0
            viewModel.messageExpandedDict[indexPath] = !isExpand
            let title = !isExpand ? L10n.MessageCardCell.Button.Expand.collapse : L10n.MessageCardCell.Button.Expand.expand(maxNumberOfLines)
            cell.expandButton.setTitle(title, for: .normal)

            tableView.beginUpdates()
            tableView.endUpdates()

            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }

}

// MARK: - For introduction wizard
extension MessagesViewController {
    func getComposeButtonFrame() -> CGRect {
        if let actionsStackView = bottomActionsView.arrangedSubviews.last as? UIStackView, let composeButton = actionsStackView.arrangedSubviews.first {
            let composeButtonFrame = composeButton.convert(composeButton.bounds, to: view)
            return composeButtonFrame
        }
        return .zero
    }
    
    func getInterpretButtonFrame() -> CGRect {
        if let actionsStackView = bottomActionsView.arrangedSubviews.last as? UIStackView, let interpretButton = actionsStackView.arrangedSubviews.last {
            let interpretButtonFrame = interpretButton.convert(interpretButton.bounds, to: view)
            return interpretButtonFrame
        }
        return .zero
    }
}
