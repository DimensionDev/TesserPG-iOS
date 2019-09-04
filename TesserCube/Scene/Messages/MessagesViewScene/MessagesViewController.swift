//
//  MessagesViewController.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/22.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import DMSOpenPGP
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

    private lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: viewModel.segmentedControlItems)
        segmentedControl.selectedSegmentIndex = 0
        return segmentedControl
    }()

    private lazy var tableHeaderView: UIView = {
        let headerView = UIView()

        if #available(iOS 13, *) {
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

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.alwaysBounceVertical = true
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 220
        tableView.register(MessageCardCell.self, forCellReuseIdentifier: String(describing: MessageCardCell.self))
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .interactive
        tableView.preservesSuperviewLayoutMargins = true
        tableView.cellLayoutMarginsFollowReadableWidth = true
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

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true

        view.addSubview(tableView)
        view.addSubview(bottomActionsView)
        addEmptyStateView(emptyView)
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            // Fallback on earlier versions
            view.backgroundColor = Asset.sceneBackground.color
        }

        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.top.bottom.equalToSuperview()
        }

        bottomActionsView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(view.readableContentGuide)
            maker.bottom.equalToSuperview().offset(-15)
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

        NotificationCenter.default.addObserver(self, selector: #selector(MessagesViewController.keyboardWillShowNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MessagesViewController.keyboardWillHideNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        viewModel.selectedMessageType.asDriver().debug().drive().disposed(by: disposeBag)
        viewModel.searchText.asDriver().debug().drive().disposed(by: disposeBag)
    }

    private func reloadActionsView() {

        bottomActionsView.arrangedSubviews.forEach {
            bottomActionsView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        var actionViews = [UIView]()

        let composeButton = TCActionButton(frame: .zero)
        composeButton.color = Asset.sketchBlue.color
        composeButton.setTitleColor(.white, for: .normal)
        composeButton.setTitle(L10n.MessagesViewController.Action.Button.compose, for: .normal)
        composeButton.addTarget(self, action: #selector(MessagesViewController.composeButtonPressed(_:)), for: .touchUpInside)

        let interpretButton = TCActionButton(frame: .zero)
        interpretButton.color = Asset.sketchBlue.color
        interpretButton.setTitleColor(.white, for: .normal)
        interpretButton.setTitle(L10n.MessagesViewController.Action.Button.interpret, for: .normal)
        interpretButton.addTarget(self, action: #selector(MessagesViewController.interpretButtonPressed(_:)), for: .touchUpInside)

        let bottomStackView = UIStackView(arrangedSubviews: [composeButton, interpretButton], axis: .horizontal, spacing: 15, alignment: .fill, distribution: .fillEqually)

        actionViews.append(bottomStackView)

        bottomActionsView.addArrangedSubviews(actionViews)

        view.layoutIfNeeded()

        defaultSafeAreaBottomInset = bottomActionsView.height + 15
        additionalSafeAreaInsets.bottom = defaultSafeAreaBottomInset
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
    }
}

private extension MessagesViewController {

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

        let actions = viewModel.tableView(tableView, presentingViewController: self, actionsforRowAt: indexPath)
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
    }

    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let message = viewModel.messages.value[indexPath.row]
        guard let cell = tableView.cellForRow(at: indexPath) as? MessageCardCell,
        let id = message.id else {
            return nil
        }

        // collapse cell before display context menu
        if viewModel.messageExpandedIDDict[id] == true {
            self.messageCardCell(cell, expandButtonPressed: cell.expandButton)
        }

        let actions = viewModel.tableView(tableView, presentingViewController: self, actionsforRowAt: indexPath)
        let children = actions.compactMap { $0.menuElement }

        return UIContextMenuConfiguration(
            identifier: indexPath as NSCopying,
            previewProvider: nil,
            actionProvider: { suggestedActions in
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
        return .topAttached
    }

}

// MARK: - UISearchControllerDelegate
extension MessagesViewController: UISearchControllerDelegate {

}

// MARK: - UISearchBarDelegate
extension MessagesViewController: UISearchBarDelegate {

}

// MARK: - UISearchResultsUpdating
extension MessagesViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        consolePrint(searchController)
    }

}

extension MessagesViewController {

    @objc private func keyboardWillShowNotification(_ notification: Notification) {
        // consolePrint(notification)
        guard let endFrame = notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? CGRect else {
            return
        }

        // consolePrint(endFrame)
        additionalSafeAreaInsets.bottom = endFrame.height - (tabBarController?.tabBar.size.height ?? 0.0)
    }

    @objc private func keyboardWillHideNotification(_ notification: Notification) {
        additionalSafeAreaInsets.bottom = defaultSafeAreaBottomInset
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
