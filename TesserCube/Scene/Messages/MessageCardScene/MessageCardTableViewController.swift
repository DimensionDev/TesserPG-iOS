//
//  MessageCardTableViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-7-19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

final class MessageCardTableViewModel: NSObject {

    private let disposeBag = DisposeBag()

    // input
    let messages = BehaviorRelay<[Message]>(value: [])
    var messageExpandedDict: [IndexPath: Bool] = [:]
    var messageMaxNumberOfLinesDict: [IndexPath: Int] = [:]

}

// MARK: - UITableViewDataSource
extension MessageCardTableViewModel: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MessageCardCell.self), for: indexPath) as! MessageCardCell
        // swiftlint:enable force_cast

        let message = messages.value[indexPath.row]
        MessagesViewModel.configure(messageCardCell: cell, with: message)

        if let isExpand = messageExpandedDict[indexPath],
            let maxNumberOfLines = messageMaxNumberOfLinesDict[indexPath] {
            cell.messageLabel.numberOfLines = isExpand ? 0 : 4
            cell.extraBackgroundViewHeightConstraint.constant = maxNumberOfLines > 4 ? 44 : 0
            let title = isExpand ? L10n.MessageCardCell.Button.Expand.collapse : L10n.MessageCardCell.Button.Expand.expand(maxNumberOfLines)
            cell.expandButton.setTitle(title, for: .normal)
        } else {
            cell.messageLabel.layoutIfNeeded()
            let maxNumberOfLines = cell.messageLabel.maxNumberOfLines
            messageExpandedDict[indexPath] = false
            messageMaxNumberOfLinesDict[indexPath] = maxNumberOfLines
            cell.messageLabel.numberOfLines = 4
            cell.extraBackgroundViewHeightConstraint.constant = maxNumberOfLines > 4 ? 44 : 0
            let title = L10n.MessageCardCell.Button.Expand.expand(maxNumberOfLines)
            cell.expandButton.setTitle(title, for: .normal)
        }

        cell.setNeedsLayout()
        cell.layoutIfNeeded()

        return cell
    }

}

final class MessageCardTableViewController: UIViewController {

    private let disposeBag = DisposeBag()
    let viewModel = MessageCardTableViewModel()

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

}

extension MessageCardTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ._systemBackground

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        tableView.dataSource = viewModel
        tableView.delegate = self

        viewModel.messages.asDriver()
            .debug()
            .drive(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }

}

// MARK: - UITableViewDelegate
extension MessageCardTableViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20 - MessageCardCell.cardVerticalMargin
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? MessageCardCell else {
            return
        }

        cell.delegate = self

        // Layout when cell display to make sure maxNumberOfLines calculated under right frame size
        cell.setNeedsLayout()
        cell.layoutIfNeeded()

        let maxNumberOfLines = cell.messageLabel.maxNumberOfLines
        viewModel.messageMaxNumberOfLinesDict[indexPath] = maxNumberOfLines
        let isExpand = viewModel.messageExpandedDict[indexPath] ?? false
        let title = isExpand ? L10n.MessageCardCell.Button.Expand.collapse : L10n.MessageCardCell.Button.Expand.expand(maxNumberOfLines)
        cell.expandButton.setTitle(title, for: .normal)
    }

}

// MARK: - MessageCardCellDelegate
extension MessageCardTableViewController: MessageCardCellDelegate {

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
