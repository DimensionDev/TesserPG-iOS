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

        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.delegate = self

        headerView.addSubview(toolbar)
        toolbar.snp.makeConstraints { maker in
            maker.top.equalTo(headerView.snp.top)
            maker.leading.trailing.equalTo(headerView)
            maker.bottom.equalTo(headerView.snp.bottom)
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
        view.backgroundColor = Asset.sceneBackground.color

        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.top.bottom.equalToSuperview()
        }

        bottomActionsView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(view.layoutMarginsGuide)
            maker.bottom.equalToSuperview().offset(-15)
        }

        tableView.delegate = self
        tableView.dataSource = viewModel
        tableView.tableHeaderView = tableHeaderView

        reloadActionsView()

        // Bind data
        ProfileService.default.messages
            .bind(to: viewModel._messages)
            .disposed(by: disposeBag)

        viewModel.messages.asDriver()
            .drive(onNext: { [weak self] _ in
                // clear cache data when data source changed
                self?.viewModel.messageExpandedDict = [:]
                self?.viewModel.messageMaxNumberOfLinesDict = [:]
                self?.tableView.reloadData()
            })
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

        let message = viewModel.messages.value[indexPath.row]
        let alertController: UIAlertController = {
            if message.isDraft {
                return DraftMessageAlertController(for: message, didSelectCell: cell)
            } else {
                let signatureKey = ProfileService.default.keys.value
                    .filter { $0.hasSecretKey }
                    .first(where: { key in key.longIdentifier == message.senderKeyId })

                let isSignedByOthers = signatureKey == nil && message.composedAt == nil
                if isSignedByOthers {
                    return ByOthersMessageAlertController(for: message, didSelectCell: cell)
                } else {
                    return EncryptedMessageAlertController(for: message, didSelectCell: cell)
                }
            }
        }()

        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
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

extension MessagesViewController {

    private func ByOthersMessageAlertController(for message: Message, didSelectCell cell: UITableViewCell) -> UIAlertController {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let copyMessageContentAction = UIAlertAction(title: L10n.MessagesViewController.Action.Button.copyMessageContent, style: .default) { _ in
            UIPasteboard.general.string = message.rawMessage
        }
        alertController.addAction(copyMessageContentAction)

        let copyRawPayLoadAction = UIAlertAction(title: L10n.MessagesViewController.Action.Button.copyRawPayload, style: .default) { _ in
            UIPasteboard.general.string = message.encryptedMessage
        }
        alertController.addAction(copyRawPayLoadAction)

        let deleteAction = UIAlertAction(title: L10n.Common.Button.delete, style: .destructive) { _ in
            let deleteMessageAlertController = self.DeleteMessageAlertController(for: message, didSelectCell: cell)
            self.present(deleteMessageAlertController, animated: true, completion: nil)
        }
        alertController.addAction(deleteAction)

        let cancelAction = UIAlertAction(title: L10n.Common.Button.cancel, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = cell
            presenter.sourceRect = cell.bounds
        }

        return alertController
    }

    private func DraftMessageAlertController(for message: Message, didSelectCell cell: UITableViewCell) -> UIAlertController {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let editAction = UIAlertAction(title: L10n.Common.Button.edit, style: .default) { _ in
            Coordinator.main.present(scene: .recomposeMessage(message: message), from: self, transition: .modal, completion: nil)
        }
        alertController.addAction(editAction)

        let finishAction = UIAlertAction(title: L10n.MessagesViewController.Action.Button.markAsFinished, style: .default) { _ in
            consolePrint(message.senderKeyId)
            let senderKey: TCKey? = ProfileService.default.keys.value.first(where: { key -> Bool in
                return key.longIdentifier == message.senderKeyId
            })
            let recipientKeys = message.getRecipients().compactMap { messageRecipient in
                return ProfileService.default.keys.value.first(where: { key in key.longIdentifier == messageRecipient.keyId })
            }
            ComposeMessageViewModel.composeMessage(message.rawMessage, to: recipientKeys, from: senderKey, password: nil)
                .subscribeOn(ConcurrentDispatchQueueScheduler.init(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] armored in
                    guard let `self` = self else { return }
                    do {
                        var message = message
                        let rawMessage = message.rawMessage
                        try message.updateDraftMessage(senderKeyID: senderKey?.longIdentifier ?? "", senderKeyUserID: senderKey?.userID ?? "", rawMessage: rawMessage, recipients: recipientKeys, isDraft: false, armoredMessage: armored)
                    } catch {
                        consolePrint(error.localizedDescription)
                    }
                }, onError: { [weak self] error in
                    guard let `self` = self else { return }
                    let message = (error as? TCError)?.errorDescription ?? error.localizedDescription
                    self.showSimpleAlert(title: L10n.Common.Alert.error, message: message)
                })
                .disposed(by: self.disposeBag)
                
        }
        alertController.addAction(finishAction)

        let deleteAction = UIAlertAction(title: L10n.Common.Button.delete, style: .destructive) { _ in
            let deleteMessageAlertController = self.DeleteMessageAlertController(for: message, didSelectCell: cell)
            self.present(deleteMessageAlertController, animated: true, completion: nil)
        }
        alertController.addAction(deleteAction)

        let cancelAction = UIAlertAction(title: L10n.Common.Button.cancel, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = cell
            presenter.sourceRect = cell.bounds
        }
        return alertController
    }

    private func EncryptedMessageAlertController(for message: Message, didSelectCell cell: UITableViewCell) -> UIAlertController {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let isCleartextMessage = DMSPGPClearTextVerifier.verify(armoredMessage: message.encryptedMessage)
        let shareActionTitle = isCleartextMessage ? L10n.MessagesViewController.Action.Button.shareSignedMessage : L10n.MessagesViewController.Action.Button.shareEncryptedMessage
        let shareArmoredMessageAction = UIAlertAction(title: shareActionTitle, style: .default) { _ in
            ShareUtil.share(message: message.encryptedMessage, from: self, over: cell)
        }
        alertController.addAction(shareArmoredMessageAction)

        let copyMessageContentAction = UIAlertAction(title: L10n.MessagesViewController.Action.Button.copyMessageContent, style: .default) { _ in
            UIPasteboard.general.string = message.rawMessage
        }
        alertController.addAction(copyMessageContentAction)

        let recomposeAction = UIAlertAction(title: L10n.MessagesViewController.Action.Button.reCompose, style: .default) { _ in
            Coordinator.main.present(scene: .recomposeMessage(message: message), from: self, transition: .modal, completion: nil)
        }
        alertController.addAction(recomposeAction)

        let deleteAction = UIAlertAction(title: L10n.Common.Button.delete, style: .destructive) { _ in
            let deleteMessageAlertController = self.DeleteMessageAlertController(for: message, didSelectCell: cell)
            self.present(deleteMessageAlertController, animated: true, completion: nil)
        }
        alertController.addAction(deleteAction)

        let cancelAction = UIAlertAction(title: L10n.Common.Button.cancel, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = cell
            presenter.sourceRect = cell.bounds
        }
        return alertController
    }

    private func DeleteMessageAlertController(for message: Message, didSelectCell cell: UITableViewCell) -> UIAlertController {
        let alertController = UIAlertController(title: L10n.MessagesViewController.Alert.Title.deleteMessage, message: nil, preferredStyle: .actionSheet)

        let confirmAction = UIAlertAction(title: L10n.Common.Button.delete, style: .destructive, handler: { _ in
            ProfileService.default.deleteMessage(message)
        })
        alertController.addAction(confirmAction)
        let cancelAction = UIAlertAction(title: L10n.Common.Button.cancel, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = cell
            presenter.sourceRect = cell.bounds
        }
        return alertController
    }

}

// MARK: - MessageCardCellDelegate
extension MessagesViewController: MessageCardCellDelegate {

    func messageCardCell(_ cell: MessageCardCell, expandButtonPressed: UIButton) {
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

// MARK: For introduction wizard
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
