//
//  RedPacketWalletProvider.swift
//  TesserCube
//
//  Created by jk234ert on 11/6/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class RedPacketWalletProvider: NSObject {
    var wallets: [String]
    
    var selectedWallet: String
    
    init(tableView: UITableView) {
        wallets = ["0x1191", "0x3389"] //TODO: Real wallets
        selectedWallet = wallets[0]
        super.init()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
    }
    
    override init() {
        fatalError("Use init(tableView:) instead")
    }
}

extension RedPacketWalletProvider: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wallets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: String(describing: Self.self))
        cell.selectionStyle = .none
        cell.textLabel?.text = wallets[indexPath.row]
        if (wallets[indexPath.row] == selectedWallet) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
}

extension RedPacketWalletProvider: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        selectedWallet = wallets[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
}
