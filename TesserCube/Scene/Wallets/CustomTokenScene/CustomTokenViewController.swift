//
//  CustomTokenViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-15.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import UIKit

final class CustomTokenViewModel: NSObject {
    
    let sections: [[TableViewCellType]] = [
        [
            .tokenAddressInput
        ],
        [
            .tokenName,
            .tokenSymbol,
            .tokenDecimals,
        ],
    ]
    
}

extension CustomTokenViewModel {
    
    enum TableViewCellType: CaseIterable {
        case tokenAddressInput
        case tokenName
        case tokenSymbol
        case tokenDecimals
    }
    
}

extension CustomTokenViewModel: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        switch sections[indexPath.section][indexPath.row] {
        case .tokenAddressInput:
        case .tokenName:
        case .tokenSymbol:
        case .tokenDecimals:
        }
        
        return cell
    }
    
}

final class CustomTokenViewController: TCBaseViewController {
    
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        
        return tableView
    }()
    
    override func configUI() {
        super.configUI()
        
        // Layout tableView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
        ])
        
        // Setup tableView data source
        tableView.delegate = self
        tableView.dataSource = viewModel
    }
    
}
