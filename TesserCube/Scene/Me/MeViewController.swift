//
//  MeViewController.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/18.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SwifterSwift
import SnapKit
import RxCocoa
import RxSwift
import ConsolePrint

class MeViewController: TCBaseViewController {
    
    let disposeBag = DisposeBag()
    
    let viewModel = MeViewModel()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.alwaysBounceVertical = true
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.register(nibWithCellClass: KeyCardCell.self)
        tableView.backgroundColor = Asset.sceneBackground.color
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
    
    private lazy var actionPromptLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = FontFamily.SFProDisplay.regular.font(size: 17)
        label.textAlignment = .center
        label.textColor = .black
        label.text = L10n.MeViewController.Action.prompt
        return label
    }()
    
    override func configUI() {
        super.configUI()

        tableView.dataSource = viewModel
        tableView.delegate = self
        
        view.addSubview(tableView)
        view.addSubview(bottomActionsView)
        
        navigationItem.rightBarButtonItem = createAddKeyBarButtonItem()
        
        bottomActionsView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(view.layoutMarginsGuide)
            maker.bottom.equalToSuperview().offset(-15)
        }
        
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        
        viewModel.hasKey
            .drive(onNext: { [weak self] result in
                self?.reloadActionsView(hasKey: result)
            })
            .disposed(by: disposeBag)
        
        viewModel.keys
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        viewModel.cellDidClick
            .subscribe(onNext: { [weak self] cell in
                switch cell.keyValue {
                case .mockKey:
                    self?.showCreateKeyAlert(onCell: cell)
                case .TCKey(let keyValue):
                    self?.showKeyActions(key: keyValue, onCell: cell)
                }
            })
            .disposed(by: disposeBag)
        
    }
    
    private func createAddKeyBarButtonItem() -> UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addKeyBarButtonItemDidClicked(_:)))
    }
    
    private func reloadActionsView(hasKey: Bool) {
        
        bottomActionsView.arrangedSubviews.forEach {
            bottomActionsView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        var actionViews = [UIView]()
        
        if !hasKey {
            let createKeyButton = TCActionButton(frame: .zero)
            createKeyButton.color = Asset.sketchBlue.color
            createKeyButton.setTitleColor(.white, for: .normal)
            createKeyButton.setTitle(L10n.MeViewController.Action.Button.createKey, for: .normal)
            createKeyButton.rx.tap.bind {
                    Coordinator.main.present(scene: .createKey, from: self, transition: .modal, completion: nil)
                }
                .disposed(by: disposeBag)
            
            let importKeyButton = TCActionButton(frame: .zero)
            importKeyButton.setTitleColor(.black, for: .normal)
            importKeyButton.setTitle(L10n.MeViewController.Action.Button.importKey, for: .normal)
            importKeyButton.rx.tap.bind {
                    Coordinator.main.present(scene: .importKey, from: self, transition: .modal, completion: nil)
                }
                .disposed(by: disposeBag)
            
            actionViews.append(actionPromptLabel)
            actionViews.append(createKeyButton)
            actionViews.append(importKeyButton)
        }
        
//        let scanQRButton = TCActionButton(frame: .zero)
//        scanQRButton.setTitleColor(.black, for: .normal)
//        scanQRButton.setTitle(L10n.MeViewController.Action.Button.scanQR, for: .normal)

        let settingsButton = TCActionButton(frame: .zero)
        settingsButton.setTitleColor(.black, for: .normal)
        settingsButton.setTitle(L10n.MeViewController.Action.Button.settings, for: .normal)
        settingsButton.addTarget(self, action: #selector(settingButtonDidClicked(_:)), for: .touchUpInside)

        let bottomStackView = UIStackView(arrangedSubviews: [settingsButton], axis: .horizontal, spacing: 15, alignment: .fill, distribution: .fillEqually)

        actionViews.append(bottomStackView)
        bottomActionsView.addArrangedSubviews(actionViews)
        view.layoutIfNeeded()
    }

}

extension MeViewController {

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        additionalSafeAreaInsets.bottom = bottomActionsView.bounds.height + 15
    }
}

extension MeViewController {
    
    @objc
    private func addKeyBarButtonItemDidClicked(_ sender: UIBarButtonItem) {
        showCreateKeyAlert(onCell: nil)
    }
    
    @objc
    private func settingButtonDidClicked(_ sender: UIButton) {
        Coordinator.main.present(scene: .settings, from: self)
    }
    
    private func showCreateKeyAlert(onCell cell: UITableViewCell?) {
        DispatchQueue.main.async {
            let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertVC.addAction(title: L10n.MeViewController.Action.Button.createKey, style: .default, isEnabled: true) { _ in
                Coordinator.main.present(scene: .createKey, from: self, transition: .modal, completion: nil)
            }
            alertVC.addAction(title: L10n.MeViewController.Action.Button.importKey, style: .default, isEnabled: true) { _ in
                Coordinator.main.present(scene: .importKey, from: self, transition: .modal, completion: nil)
            }
            alertVC.addAction(UIAlertAction(title: L10n.Common.Button.cancel, style: .cancel, handler: nil))
            if let presenter = alertVC.popoverPresentationController {
                if let cell = cell {
                    presenter.sourceView = cell
                    presenter.sourceRect = cell.bounds
                } else {
                    presenter.barButtonItem = self.navigationItem.rightBarButtonItem
                }

            }
            self.present(alertVC, animated: true)
        }
    }
    
    private func showKeyActions(key: TCKey, onCell cell: UITableViewCell) {
        DispatchQueue.main.async {
            let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertVC.addAction(title: L10n.MeViewController.Action.Button.share, style: .default, isEnabled: true) { _ in
                ShareUtil.share(key: key, from: self, over: cell)
            }
            alertVC.addAction(title: L10n.MeViewController.Action.Button.export, style: .destructive, isEnabled: true) { _ in
                // TODO: or input password manually?
                ShareUtil.export(key: key, from: self, over: cell)
            }
            alertVC.addAction(title: L10n.Common.Button.delete, style: .destructive, isEnabled: true) { _ in
                self.showDeleteConfirmAlert(key: key)
            }
            alertVC.addAction(UIAlertAction(title: L10n.Common.Button.cancel, style: .cancel, handler: nil))
            if let presenter = alertVC.popoverPresentationController {
                presenter.sourceView = cell
                presenter.sourceRect = cell.bounds
            }
            self.present(alertVC, animated: true)
        }
    }
    
    private func showDeleteConfirmAlert(key: TCKey) {
        DispatchQueue.main.async {
            let confirmMessage = L10n.MeViewController.Action.Button.confirmDeleteKey + key.shortIdentifier
            let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertVC.addAction(title: confirmMessage, style: .destructive, isEnabled: true) { [weak self] _ in
                guard let `self` = self else { return }
                self.viewModel.deleteKey(key, completion: { error in
                    consolePrint(error?.localizedDescription)
                })
            }
            alertVC.addAction(title: L10n.Common.Button.cancel, style: .cancel, isEnabled: true)
            if let presenter = alertVC.popoverPresentationController {
                presenter.sourceView = self.view
                presenter.sourceRect = CGRect(origin: self.view.center, size: .zero)
                presenter.permittedArrowDirections = []
            }
            self.present(alertVC, animated: true)
        }
    }
}

extension MeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 126
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? KeyCardCell else { return }
        viewModel.cellDidClick.accept(cell)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }

}
