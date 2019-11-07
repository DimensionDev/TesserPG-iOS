//
//  RedPacketSplitMethodProvider.swift
//  TesserCube
//
//  Created by jk234ert on 11/6/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class RedPacketSplitMethodProvider: NSObject {
    
    var selectedSplitType: RedPacketProperty.SplitType
    
    init(redPacketProperty: RedPacketProperty, tableView: UITableView) {
        selectedSplitType = redPacketProperty.splitType
        super.init()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
    }
    
    override init() {
        fatalError("Use init(tableView:) instead")
    }
}

extension RedPacketSplitMethodProvider: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return RedPacketProperty.SplitType.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: String(describing: Self.self))
        cell.selectionStyle = .none
        cell.textLabel?.text = RedPacketProperty.SplitType.allCases[indexPath.row].title
        if RedPacketProperty.SplitType.allCases[indexPath.row] == selectedSplitType {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
}

extension RedPacketSplitMethodProvider: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        selectedSplitType = RedPacketProperty.SplitType.allCases[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
}
