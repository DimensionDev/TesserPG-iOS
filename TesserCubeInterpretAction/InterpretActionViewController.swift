//
//  InterpretActionViewController.swift
//  TesserCubeInterpretAction
//
//  Created by Cirno MainasuK on 2019-7-16.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MobileCoreServices
import BouncyCastle_ObjC
import DMSOpenPGP
import ConsolePrint

final class InterpretActionViewController: UIViewController {

    private let disposeBag = DisposeBag()

    let contentViewController: UIViewController = {
        let controller = UIViewController()
        controller.view.backgroundColor = Asset.sceneBackground.color
        return controller
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
        stackView.spacing = 15
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        return stackView
    }()

    private lazy var brokenMessageViewController = BrokenMessageViewController()

    let viewModel = InterpretActionViewModel()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        _init()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _init()
    }

    @IBAction func doneBarButtonItemPressed(_ sender: UIBarButtonItem) {
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }

    private func _init() {
        // Setup Bouncy Castle
        JavaSecuritySecurity.addProvider(with: OrgBouncycastleJceProviderBouncyCastleProvider())
    }

}

extension InterpretActionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.title.asDriver().drive(rx.title).disposed(by: disposeBag)
        view.backgroundColor = Asset.sceneBackground.color

        // Use content view controller to make addtional safe area insets
        addChild(contentViewController)
        view.addSubview(contentViewController.view)
        contentViewController.didMove(toParent: self)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        contentViewController.view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: contentViewController.view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: contentViewController.view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentViewController.view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentViewController.view.bottomAnchor),
        ])

        bottomActionsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomActionsView)
        let bottomActionsViewBottomConstraint = bottomActionsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        bottomActionsViewBottomConstraint.priority = .defaultLow
        NSLayoutConstraint.activate([
            bottomActionsView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            bottomActionsView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            view.bottomAnchor.constraint(greaterThanOrEqualTo: bottomActionsView.bottomAnchor, constant: 16),
            bottomActionsViewBottomConstraint,
        ])

        tableView.dataSource = viewModel
        tableView.delegate = self

        // reload data source when table view set right frame
        viewModel.messageExpandedDict = [:]
        viewModel.messageMaxNumberOfLinesDict = [:]
        viewModel.message.asDriver()
            .drive(onNext: { [weak self] message in
                guard let `self` = self else { return }
                self.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        viewModel.message.asDriver()
            .debug()
            .skip(1)
            .drive(onNext: { [weak self] message in
                guard let `self` = self else { return }
                let controller = self.brokenMessageViewController

                guard message == nil else {
                    if controller.parent != nil {
                        controller.willMove(toParent: nil)
                        controller.view.removeFromSuperview()
                        controller.removeFromParent()
                    }
                    return
                }

                if controller.parent == nil {
                    self.addChild(controller)
                    self.view.addSubview(controller.view)
                    controller.didMove(toParent: self)

                    controller.messageLabel.text = self.viewModel.inputTexts.joined(separator: "\n")
                }
            })
            .disposed(by: disposeBag)
        viewModel.availableActions.asDriver()
            .drive(onNext: { [weak self] actions in
                self?.reloadBottomActionView(with: actions)
            })
            .disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        extractInputFromExtensionContext()
    }

}

extension InterpretActionViewController {

    private func extractInputFromExtensionContext() {
        // check input text
        let providers = extensionContext
            .flatMap { $0.inputItems as? [NSExtensionItem] }
            .flatMap { items in return items.compactMap { $0.attachments }.flatMap { $0 } } ?? []

        guard !providers.isEmpty else {
            assertionFailure()
            return
        }

        for (i, provider) in providers.enumerated() {
            consolePrint(provider)

            let typeIdentifier = kUTTypePlainText as String
            guard provider.hasItemConformingToTypeIdentifier(typeIdentifier) else { continue }

            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] text, error in
                guard let `self` = self else { return }
                guard error == nil else { return }
                guard let text = text as? String else { return }

                self.viewModel.inputTexts.append(text)

                if i == providers.count - 1 {
                    // notify viewModel done
                    DispatchQueue.main.async { [weak self] in
                        self?.viewModel.finalizeInput()
                    }
                }
            }
        }   // end for … in …
    }

}

extension InterpretActionViewController {

    private func reloadBottomActionView(with actions: [InterpretActionViewModel.Action]) {
        bottomActionsView.arrangedSubviews.forEach {
            bottomActionsView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        if actions.contains(.copy) {
            let copyButton = TCActionButton(frame: .zero)
            copyButton.color = .white
            copyButton.setTitleColor(.black, for: .normal)
            copyButton.setTitle(L10n.InterpretActionViewController.Action.Button.copyContent, for: .normal)
            copyButton.addTarget(self, action: #selector(InterpretActionViewController.composeButtonPressed(_:)), for: .touchUpInside)

            bottomActionsView.addArrangedSubview(copyButton)
        }

        if actions.contains(.reply) {
            let replyButton = TCActionButton(frame: .zero)
            replyButton.color = Asset.sketchBlue.color
            replyButton.setTitleColor(.white, for: .normal)
            replyButton.setTitle(L10n.InterpretActionViewController.Action.Button.writeReply, for: .normal)
            replyButton.addTarget(self, action: #selector(InterpretActionViewController.interpretButtonPressed(_:)), for: .touchUpInside)

            bottomActionsView.addArrangedSubview(replyButton)
        }

        bottomActionsView.setNeedsLayout()
        bottomActionsView.layoutIfNeeded()

        contentViewController.additionalSafeAreaInsets.bottom = bottomActionsView.frame.height + 15 // add some spacing to cell
    }

    @objc private func composeButtonPressed(_ sender: UIButton) {
        viewModel.copyAction.accept(sender)
    }

    @objc private func interpretButtonPressed(_ sender: UIButton) {
//        Coordinator.main.present(scene: .interpretMessage, from: self, transition: .modal, completion: nil)
    }

}

// MARK: - UITableViewDelegate
extension InterpretActionViewController: UITableViewDelegate {

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
extension InterpretActionViewController: MessageCardCellDelegate {

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
