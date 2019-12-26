//
//  WalletsViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-6.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import UIKit
import RxSwift
import RxCocoa
import RxRealm

class WalletsViewController: TCBaseViewController {

    private(set) lazy var viewModel = WalletsViewModel()
    private let disposeBag = DisposeBag()
    
    private let longPressGestureRecognizer = UILongPressGestureRecognizer()

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(WalletCollectionTableViewCell.self, forCellReuseIdentifier: String(describing: WalletCollectionTableViewCell.self))
        tableView.register(RedPacketCardTableViewCell.self, forCellReuseIdentifier: String(describing: RedPacketCardTableViewCell.self))
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
        
        do {
            let realm = try RedPacketService.realm()
            let redPacketResults = realm.objects(RedPacket.self)
            Observable.array(from: redPacketResults, synchronousStart: false)
                .subscribe(onNext: { [weak self] redPackets in
                    guard let `self` = self else { return }
                    
                    // update view model data source
                    self.viewModel.redPackets.accept(redPackets.reversed())
                    
                    // fetch create result
                    let pendingRedPackets = redPackets.filter { $0.status == .pending }
                    for redPacket in pendingRedPackets {
                        RedPacketService.shared.updateCreateResult(for: redPacket)
                            .subscribe()
                            .disposed(by: self.disposeBag)
                    }
                    
                    // fetch claim result
                    let claimPendingRedPackets = redPackets.filter { $0.status == .claim_pending }
                    for redPacket in claimPendingRedPackets {
                        RedPacketService.shared.updateClaimResult(for: redPacket)
                            .subscribe()
                            .disposed(by: self.disposeBag)
                    }
                    
                })
                .disposed(by: disposeBag)
    
        } catch {
            os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            assertionFailure()
        }
        
        tableView.delegate = self
        tableView.dataSource = viewModel
        
        // Setup long press gesture for tableView for early iOS 13.0 to trigger alert sheet menu
        if #available(iOS 13.0, *) {
            // do nothing
        } else {
            tableView.addGestureRecognizer(longPressGestureRecognizer)
            longPressGestureRecognizer.addTarget(self, action: #selector(WalletsViewController.longPressGesture(_:)))
        }
    }

}

extension WalletsViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.once {
            self.viewModel.walletModels.accept(WalletService.default.walletModels.value)
            self.tableView.reloadData()
            
            self.viewModel.filteredRedPackets.asDriver()
                .distinctUntilChanged()
                .drive(onNext: { [weak self] _ in
                    guard let `self` = self else { return }
                    self.reloadActionsView()
                    
                    // reload red packet section
                    os_log("%{public}s[%{public}ld], %{public}s: filteredRedPackets changed. reload table view", ((#file as NSString).lastPathComponent), #line, #function)
                    
                    let sections: IndexSet = [1]
                    self.tableView.reloadSections(sections, with: .automatic)
                })
                .disposed(by: disposeBag)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.contentInset.bottom = bottomActionsView.height + 15
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
        
        // trigger tableView content inset update
        view.layoutIfNeeded()
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
        
        let buttonStackView = UIStackView()
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 15
        buttonStackView.axis = .horizontal
        
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
        
        let openRedPacketButton: TCActionButton = {
            let button = TCActionButton(frame: .zero)
            button.color = .systemBlue
            button.setTitleColor(.white, for: .normal)
            button.setTitle("Open Red Packet", for: .normal)
            button.rx.tap.bind {
                Coordinator.main.present(scene: .openRedPacket, from: self, transition: .modal, completion: nil)
            }
            .disposed(by: disposeBag)
            return button
        }()
        
        buttonStackView.addArrangedSubview(sendRedPacketButton)
        buttonStackView.addArrangedSubview(openRedPacketButton)

        actionViews.append(buttonStackView)
        
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
    
    @objc private func longPressGesture(_ sender: UILongPressGestureRecognizer) {
        guard case .began = sender.state else {
            return
        }
        
        // Present wallet alert sheet menu when long press
        let position = sender.location(in: tableView)
        guard let indexPathForTableViewCell = tableView.indexPathForRow(at: position),
        let walletCollectionTableViewCell = tableView.cellForRow(at: indexPathForTableViewCell) as? WalletCollectionTableViewCell else {
            return
        }
        
        let collectionView = walletCollectionTableViewCell.collectionView
        let positionInCollectionView = sender.location(in: collectionView)
        guard let indexPathForCollectionViewCell = collectionView.indexPathForItem(at: positionInCollectionView),
        let walletCardCollectionViewCell = collectionView.cellForItem(at: indexPathForCollectionViewCell) as? WalletCardCollectionViewCell else {
            return
        }
        
        guard let actions = viewModel.collectionView(collectionView, presentingViewController: self, isContextMenu: false, actionsForRowA: indexPathForCollectionViewCell),
        !actions.isEmpty else {
            return
        }
        
        let alertController: UIAlertController = {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let alertActions = actions.map { $0.alertAction }
            for alertAction in alertActions {
                alertController.addAction(alertAction)
            }
            return alertController
        }()
        
        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = walletCardCollectionViewCell
        }
        
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
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
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch WalletsViewModel.Section.allCases[indexPath.section] {
        case .wallet:
            guard let cell = cell as? WalletCollectionTableViewCell else {
                return
            }
            
            // Set delegate to flow layout
            cell.collectionView.delegate = self
            
        default:
            return
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch WalletsViewModel.Section.allCases[indexPath.section] {
        case .wallet:
            return

        case .redPacket:
            guard let cell = tableView.cellForRow(at: indexPath) as? RedPacketCardTableViewCell,
            indexPath.row < viewModel.filteredRedPackets.value.count else {
                return
            }
            let redPacket = viewModel.filteredRedPackets.value[indexPath.row]
            
            if redPacket.status == .normal || redPacket.status == .incoming {
                // ready to claim
                let viewModel = ClaimRedPacketViewModel(redPacket: redPacket)
                Coordinator.main.present(scene: .claimRedPacket(viewModel: viewModel), from: self, transition: .modal, completion: nil)
            } else {
                // check detail
                // TODO:
            }
        }  
    }

    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        // switch WalletsViewModel.Section.allCases[indexPath.section] {
        // case .wallet:
        //     return nil
        // case .redPacket:
        //
        // }
        // guard indexPath.section == 1,
        // let cell = tableView.cellForRow(at: indexPath) as? WalletCardTableViewCell else {
        //     return nil
        // }

        guard let actions = viewModel.tableView(tableView, presentingViewController: self, isContextMenu: true, actionsforRowAt: indexPath),
        !actions.isEmpty else {
            return nil
        }
        
        let children = actions.compactMap { $0.menuElement }

        return UIContextMenuConfiguration(
            identifier: indexPath as NSCopying,
            previewProvider: nil,
            actionProvider: { _ in
                return UIMenu(title: "", image: nil, identifier: nil, options: [], children: children)
            }
        )
    }

    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath else {
            return nil
        }

        guard case .redPacket = WalletsViewModel.Section.allCases[indexPath.section] else {
            return nil
        }

        guard let cell = tableView.cellForRow(at: indexPath) as? RedPacketCardTableViewCell else {
            return nil
        }
        
        
        let parameters = UIPreviewParameters()
        return UITargetedPreview(view: cell.cardView, parameters: parameters)
    }
    
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath else {
            return nil
        }

        guard case .redPacket = WalletsViewModel.Section.allCases[indexPath.section] else {
            return nil
        }

        guard let cell = tableView.cellForRow(at: indexPath) as? RedPacketCardTableViewCell else {
            return nil
        }
        
        let parameters = UIPreviewParameters()
        return UITargetedPreview(view: cell.cardView, parameters: parameters)
    }

}

// MARK: - UICollectionViewDelegate
extension WalletsViewController: UICollectionViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let collectionView = scrollView as? UICollectionView, collectionView.tag == WalletCollectionTableViewCell.collectionViewTag else {
            return
        }
        
        let displayCenterOffsetX = scrollView.contentOffset.x + 0.5 * collectionView.bounds.width
        let displayCenterOffset = CGPoint(x: displayCenterOffsetX, y: 0.5 * collectionView.height)
        guard let currentDisplayCellIndexPath = collectionView.indexPathForItem(at: displayCenterOffset) else {
            return
        }
        
        // update page control and currentWalletModel after wallets collection view scroll
        let index = currentDisplayCellIndexPath.row
        viewModel.currentWalletPageIndex.accept(index)
        
        guard index < viewModel.walletModels.value.count else {
            return
        }
        viewModel.currentWalletModel.accept(viewModel.walletModels.value[index])
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView.tag == WalletCollectionTableViewCell.collectionViewTag else {
            return
        }
    
        guard let walletCardCollectionViewCell = collectionView.cellForItem(at: indexPath) as? WalletCardCollectionViewCell else {
            return
        }
        
        guard let actions = viewModel.collectionView(collectionView, presentingViewController: self, isContextMenu: false, actionsForRowA: indexPath),
        !actions.isEmpty else {
            return
        }
        
        let alertController: UIAlertController = {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let alertActions = actions.map { $0.alertAction }
            for alertAction in alertActions {
                alertController.addAction(alertAction)
            }
            return alertController
        }()
        
        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = walletCardCollectionViewCell
        }
        
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let _ = cell as? WalletCardCollectionViewCell else {
            return
        }
        
        guard indexPath.row < viewModel.walletModels.value.count else {
            return
        }

        // trigger balance update when cell will display
        viewModel.walletModels.value[indexPath.row].updateBalance()
    }
    
    @available(iOS 13.0, *)
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        guard let actions = viewModel.collectionView(collectionView, presentingViewController: self, isContextMenu: true, actionsForRowA: indexPath),
        !actions.isEmpty else {
            return nil
        }
        
        let children = actions.compactMap { $0.menuElement }
        
        return UIContextMenuConfiguration(
            identifier: indexPath as NSCopying,
            previewProvider: nil,
            actionProvider: { _ in
                return UIMenu(title: "", image: nil, identifier: nil, options: [], children: children)
            }
        )
    }
    
    @available(iOS 13.0, *)
    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath else {
            return nil
        }
        
        guard case .wallet = WalletsViewModel.Section.allCases[indexPath.section] else {
            return nil
        }
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? WalletCardCollectionViewCell else {
            return nil
        }
        
        let parameters = UIPreviewParameters()
        return UITargetedPreview(view: cell.walletCardView, parameters: parameters)
    }
    
    @available(iOS 13.0, *)
    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath else {
            return nil
        }
        
        guard case .wallet = WalletsViewModel.Section.allCases[indexPath.section] else {
            return nil
        }
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? WalletCardCollectionViewCell else {
            return nil
        }
        
        let parameters = UIPreviewParameters()
        return UITargetedPreview(view: cell.walletCardView, parameters: parameters)
    }
    
}

// MAKR: - UICollectionViewDelegateFlowLayout
extension WalletsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.bounds.width - view.layoutMargins.left - view.layoutMargins.right,
                      height: WalletCollectionTableViewCell.cellHeight + 2 * WalletCardCollectionViewCell.cardVerticalMargin)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: view.layoutMargins.left, bottom: 0, right: view.layoutMargins.right)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return view.layoutMargins.left + view.layoutMargins.right
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}
