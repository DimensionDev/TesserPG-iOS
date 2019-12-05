//
//  RedPacketWalletProvider.swift
//  TesserCube
//
//  Created by jk234ert on 11/6/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class RedPacketWalletProvider: NSObject {
    
    // Input
    let walletModels: [WalletModel]
    private(set) weak var tableView: UITableView?
    
    // Output
    private(set) var selectIndexPath = IndexPath(row: 0, section: 0) {
        didSet {
            if selectIndexPath.row < walletModels.count {
                selectWalletModel.accept(walletModels[selectIndexPath.row])
            } else {
                selectWalletModel.accept(nil)
            }
        }
    }
    let selectWalletModel = BehaviorRelay<WalletModel?>(value: nil)
    
    init(tableView: UITableView, walletModels: [WalletModel]) {
        self.tableView = tableView
        self.walletModels = walletModels
        
        super.init()
                
        tableView.delegate = self
        tableView.dataSource = self
        
        // Select first
        tableView.selectRow(at: selectIndexPath, animated: false, scrollPosition: .none)
        selectWalletModel.accept(walletModels.first)
    }
    
    override init() {
        fatalError("Use init(tableView:) instead")
    }
}

extension RedPacketWalletProvider: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return walletModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "DefaultCell")
        
        cell.contentView.backgroundColor = ._secondarySystemGroupedBackground
        cell.selectionStyle = .none
        cell.textLabel?.text =  walletModels[indexPath.row].address
        
        cell.accessoryType = indexPath == selectIndexPath ? .checkmark : .none
        
        return cell
    }
}

extension RedPacketWalletProvider: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        selectIndexPath = indexPath
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
        selectIndexPath = indexPath
    }
}
