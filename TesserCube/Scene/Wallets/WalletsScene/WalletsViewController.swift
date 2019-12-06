//
//  WalletsViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-6.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift

class WalletsViewController: TCBaseViewController {

    let viewModel = WalletsViewModel()
    private let disposeBag = DisposeBag()

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(WalletCardTableViewCell.self, forCellReuseIdentifier: String(describing: WalletCardTableViewCell.self))
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
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

        title = L10n.MainTabbarViewController.TabBarItem.Wallets.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(WalletsViewController.addBarButtonItemPressed(_:)))

        // Layout tableView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Layout bottom actions view
        bottomActionsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomActionsView)
        NSLayoutConstraint.activate([
            bottomActionsView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            bottomActionsView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: bottomActionsView.bottomAnchor, constant: 15),
        ])

        // Setup tableView
        WalletService.default.walletModels.asDriver()
            .drive(viewModel.walletModels)
            .disposed(by: disposeBag)
        tableView.dataSource = viewModel
        viewModel.walletModels.asDriver()
            .drive(onNext: { [weak self] _ in
                self?.reloadActionsView()
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        tableView.delegate = self
    }

}

extension WalletsViewController {

    private func reloadActionsView() {
        bottomActionsView.arrangedSubviews.forEach {
            bottomActionsView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        if viewModel.walletModels.value.isEmpty {
            layoutWalletActions()
        } else {
            layoutRedPacketActions()
        }
    }
    
    private func layoutWalletActions() {
        var actionViews = [UIView]()
        
        let actionPromptLabel: UILabel = {
            let label = UILabel(frame: .zero)
            label.font = FontFamily.SFProDisplay.regular.font(size: 17)
            label.textAlignment = .center
            label.textColor = ._label
            label.text = "Create or import wallet to start using."
            return label
        }()
        
        let createWalletButton: TCActionButton = {
            let button = TCActionButton(frame: .zero)
            button.color = .systemBlue
            button.setTitleColor(.white, for: .normal)
            button.setTitle("Create Wallet", for: .normal)
            button.rx.tap.bind {
                Coordinator.main.present(scene: .createWallet, from: self, transition: .modal, completion: nil)
            }
            .disposed(by: disposeBag)
            return button
        }()
        
        let importKeyButton: TCActionButton = {
            let button = TCActionButton(frame: .zero)
            button.color = ._secondarySystemBackground
            button.setTitleColor(._label, for: .normal)
            button.setTitle("Import Wallet", for: .normal)
            button.rx.tap.bind {
                Coordinator.main.present(scene: .importWallet, from: self, transition: .modal, completion: nil)
            }
            .disposed(by: disposeBag)
            return button
        }()
        
        actionViews.append(actionPromptLabel)
        actionViews.append(createWalletButton)
        actionViews.append(importKeyButton)
        
        bottomActionsView.addArrangedSubviews(actionViews)
        bottomActionsView.setNeedsLayout()
    }
    
    private func layoutRedPacketActions() {
        var actionViews = [UIView]()
        
        let sendRedPacketButton: TCActionButton = {
            let button = TCActionButton(frame: .zero)
            button.color = .systemBlue
            button.setTitleColor(.white, for: .normal)
            button.setTitle("Send Red Packet", for: .normal)
            button.rx.tap.bind {
                guard !WalletService.default.walletModels.value.isEmpty else {
                    let alertController = UIAlertController(title: "Error", message: "Please create a wallet first", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: L10n.Common.Button.ok, style: .default, handler: nil)
                    alertController.addAction(okAction)
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.present(alertController, animated: true, completion: nil)
                    }
                    
                    return
                }
                
                Coordinator.main.present(scene: .sendRedPacket, from: self, transition: .modal, completion: nil)
            }
            .disposed(by: disposeBag)
            return button
        }()

        actionViews.append(sendRedPacketButton)
        
        bottomActionsView.addArrangedSubviews(actionViews)
        bottomActionsView.setNeedsLayout()
    }

}

extension WalletsViewController {

    @objc private func addBarButtonItemPressed(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let createWalletAction = UIAlertAction(title: "Create Wallet", style: .default) { _ in
            Coordinator.main.present(scene: .createWallet, from: self, transition: .modal, completion: nil)
        }
        alertController.addAction(createWalletAction)
        let importWalletAction = UIAlertAction(title: "Import Wallet", style: .default) { _ in
            Coordinator.main.present(scene: .importWallet, from: self, transition: .modal, completion: nil)
        }
        alertController.addAction(importWalletAction)
        let cancelAction = UIAlertAction(title: L10n.Common.Button.cancel, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.barButtonItem = sender
        }
        present(alertController, animated: true, completion: nil)
    }
    
}

// MARK: - UITableViewDelegate
extension WalletsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == 1 else {
            return .leastNonzeroMagnitude
        }

        return 20 - WalletCardTableViewCell.cardVerticalMargin
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard section == 1 else {
            return .leastNonzeroMagnitude
        }
        
        return 20 - WalletCardTableViewCell.cardVerticalMargin
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // guard cell for walletModels data
        guard indexPath.section == 1,
        let cell = tableView.cellForRow(at: indexPath) as? WalletCardTableViewCell else {
            return
        }

        let actions = viewModel.tableView(tableView, presentingViewController: self, actionsforRowAt: indexPath, isContextMenu: false)
        let alertController: UIAlertController = {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let alertActions = actions.map { $0.alertAction }
            for alertAction in alertActions {
                alertController.addAction(alertAction)
            }
            return alertController
        }()

        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = cell
        }

        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }

    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard indexPath.section == 1,
        let cell = tableView.cellForRow(at: indexPath) as? WalletCardTableViewCell else {
            return nil
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
        let cell = tableView.cellForRow(at: indexPath) as? WalletCardTableViewCell else {
            return nil
        }

        let parameters = UIPreviewParameters()
        return UITargetedPreview(view: cell.cardView, parameters: parameters)
    }
    
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
            let cell = tableView.cellForRow(at: indexPath) as? WalletCardTableViewCell else {
                return nil
        }
        
        let parameters = UIPreviewParameters()
        return UITargetedPreview(view: cell.cardView, parameters: parameters)
    }

}
