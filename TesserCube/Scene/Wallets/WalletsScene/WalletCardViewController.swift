//
//  WalletCardViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-17.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

final class WalletCardViewController: UIViewController {
    
    var index: Int = 0
    // Display stub cell if not set value
    var walletModel: WalletModel? {
        didSet {
            tableView.reloadData()
        }
    }
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(WalletCardTableViewCell.self, forCellReuseIdentifier: String(describing: WalletCardTableViewCell.self))
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.alwaysBounceVertical = false
        tableView.clipsToBounds = false
        tableView.backgroundColor = .clear
        return tableView
    }()
    
}

extension WalletCardViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Layout tableView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
    }
}

// MARK: - UITableViewDataSource
extension WalletCardViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: WalletCardTableViewCell.self), for: indexPath) as! WalletCardTableViewCell
        
        if let walletModel = self.walletModel {
            WalletsViewModel.configure(cell: cell, with: walletModel)
        }
        
        return cell
    }
    
}

// MARK: - UITableViewDelegate
extension WalletCardViewController: UITableViewDelegate {
    
}
