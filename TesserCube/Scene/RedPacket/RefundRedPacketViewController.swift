//
//  RefundRedPacketViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-30.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import UIKit
import RealmSwift
import RxSwift
import RxCocoa
import RxRealm

final class RefundRedPacketViewModel: NSObject {
    
    // Input
    let redPacket: RedPacket
    
    // Output
    var redPacketNotificationToken: NotificationToken?
    
    init(redPacket: RedPacket) {
        self.redPacket = redPacket
        super.init()
        
    }
    
    deinit {
        redPacketNotificationToken?.invalidate()
        os_log("%{public}s[%{public}ld], %{public}s: deinit", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

// MARK: - UITableViewDataSource
extension RefundRedPacketViewModel: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RedPacketCardTableViewCell.self), for: indexPath) as! RedPacketCardTableViewCell
        CreatedRedPacketViewModel.configure(cell: cell, with: redPacket)
        return cell
    }
    
}

final class RefundRedPacketViewController: TCBaseViewController {
    
    let disposeBag = DisposeBag()
    
    var viewModel: RefundRedPacketViewModel!
    
    private lazy var closeBarButtonItem: UIBarButtonItem = {
        if #available(iOS 13.0, *) {
            return UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(RefundRedPacketViewController.closeBarButtonItemPressed(_:)))
        } else {
            return UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(RefundRedPacketViewController.closeBarButtonItemPressed(_:)))
        }
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(RedPacketCardTableViewCell.self, forCellReuseIdentifier: String(describing: RedPacketCardTableViewCell.self))
        tableView.separatorStyle = .none
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
    
    lazy var refundRedPacketButton: TCActionButton = {
        let button = TCActionButton()
        button.color = .systemBlue
        button.setTitle("Refund Red Packet", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(RefundRedPacketViewController.refundRedPacketButtonPressed(_:)), for: .touchUpInside)
        return button
    }()

    override func configUI() {
        super.configUI()
        
        title = "Refund Red Packet"
        navigationItem.leftBarButtonItem = closeBarButtonItem
        
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
        
        reloadActionsView()
        
        // Setup table view
        tableView.delegate = self
        tableView.dataSource = viewModel
        
        // update table view when red packet changes
        viewModel.redPacketNotificationToken = viewModel.redPacket.observe { [weak self] change in
            guard let `self` = self else { return }
            switch change {
            case .change(let changes):
                // self.viewModel.isClaimPending.accept(self.viewModel.redPacket.status == .claim_pending)
                self.tableView.reloadData()
                os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, changes.description)
                
            default:
                break
            }
        }
    }
    
}

extension RefundRedPacketViewController {
    
    private func reloadActionsView() {
        bottomActionsView.arrangedSubviews.forEach { subview in
            bottomActionsView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        bottomActionsView.addArrangedSubview(refundRedPacketButton)
    }
    
}

extension RefundRedPacketViewController {
    
    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func refundRedPacketButtonPressed(_ sender: UIButton) {
        
    }
    
}

// MARK: - UITableViewDelegate
extension RefundRedPacketViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
    
}
