//
//  WalletsViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-6.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

class WalletsViewModel: NSObject {

    let walletModels = BehaviorRelay<[WalletModel]>(value: [])

    override init() {
        super.init()
    }

}

// MARK: - UITableViewDataSource
extension WalletsViewModel: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return walletModels.value.isEmpty ? 1 : 0
        case 1:
            return walletModels.value.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: WalletCardTableViewCell.self), for: indexPath) as! WalletCardTableViewCell

        switch indexPath.section {
        case 1:
            let model = walletModels.value[indexPath.row]
            WalletsViewModel.configure(cell: cell, with: model)
        default:
            break
        }

        return cell
    }

}

extension WalletsViewModel {

    static func configure(cell: WalletCardTableViewCell, with model: WalletModel) {
        let address = try? model.hdWallet?.address()
        cell.headerLabel.text = address.flatMap { "0x" + $0.suffix(4) }
        cell.captionLabel.text = address
//            cell.captionLabel.text = {
//                guard let address = address else { return nil }
//                let raw = address.removingPrefix("0x")
//                return "0x" + raw.prefix(20) + "\n" + raw.suffix(20)
//            }()
            // TODO: Balance
    }

}

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

        // Not layout button when have data
        guard viewModel.walletModels.value.isEmpty else {
            return
        }

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
        return 20 - WalletCardTableViewCell.cardVerticalMargin
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20 - WalletCardTableViewCell.cardVerticalMargin
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // guard cell for walletModels data
        guard indexPath.section == 1,
        let cell = tableView.cellForRow(at: indexPath) as? WalletCardTableViewCell else {
            return
        }

        let model = viewModel.walletModels.value[indexPath.row]
        let service = WalletService.default
        let walletName = cell.headerLabel.text
        
        let alertController = UIAlertController(title: nil, message: walletName, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: L10n.Common.Button.delete, style: .destructive) { [weak self] _ in
            let confirmDeleteAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let title = ["Yes. Delete", walletName].compactMap { $0 }.joined(separator: " ")
            let deleteAction = UIAlertAction(title: title, style: .destructive) { _ in
                service.remove(wallet: model.wallet)
            }
            confirmDeleteAlertController.addAction(deleteAction)
            let cancelAction = UIAlertAction(title: L10n.Common.Button.cancel, style: .cancel, handler: nil)
            confirmDeleteAlertController.addAction(cancelAction)
            if let popoverPresentationController = confirmDeleteAlertController.popoverPresentationController {
                popoverPresentationController.sourceView = cell
            }
            self?.present(confirmDeleteAlertController, animated: true, completion: nil)
        }
        alertController.addAction(deleteAction)

        let cancelAction = UIAlertAction(title: L10n.Common.Button.cancel, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = cell
        }

        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }

}
