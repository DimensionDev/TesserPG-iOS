//
//  RedPacketWalletSelectViewController.swift
//  TesserCube
//
//  Created by jk234ert on 12/12/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import UIKit
import RxSwift
import RxCocoa
import DMS_HDWallet_Cocoa

protocol RedPacketWalletSelectViewControllerDelegate: class {
    func redPacketWalletSelectViewController(_ viewController: RedPacketWalletSelectViewController, didSelect wallet: WalletModel)
}

class RedPacketWalletSelectViewController: UIViewController {
    
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        return tableView
    }()
    
    var delegate: RedPacketWalletSelectViewControllerDelegate?
    
    var wallets: [WalletModel] = []
    var selectedWallet: WalletModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Select Wallet"
    
        // Layout tableView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        // Setup tableView
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension RedPacketWalletSelectViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wallets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RedPacketWalletSelectViewController.self)) else {
                return UITableViewCell(style: .default, reuseIdentifier: String(describing: RedPacketWalletSelectViewController.self))
            }
            return cell
        }()

        let wallet = wallets[indexPath.row]
        cell.textLabel?.text = "Wallet \(wallet.address.prefix(6))"
        
        if wallet.address == selectedWallet?.address {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }
}

extension RedPacketWalletSelectViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let wallet = wallets[indexPath.row]
        delegate?.redPacketWalletSelectViewController(self, didSelect: wallet)
    }
}
