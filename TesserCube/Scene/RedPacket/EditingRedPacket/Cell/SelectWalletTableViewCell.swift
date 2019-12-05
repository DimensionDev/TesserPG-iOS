//
//  SelectWalletTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-22.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

final class SelectWalletTableViewCell: UITableViewCell, LeftDetailStyle {
        
    let titleLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    var detailLeadingLayoutConstraint: NSLayoutConstraint!
    
    let tableView: DynamicTableView = {
        let tableView = DynamicTableView()
        tableView.separatorInset = .zero
        return tableView
    }()
    let walletBalanceLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 12)
        label.textColor = ._secondaryLabel
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    private func _init() {
        selectionStyle = .none
        contentView.backgroundColor = ._systemGroupedBackground
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalToSystemSpacingBelow: contentView.topAnchor, multiplier: 1.0),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
        ])
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tableView)
        detailLeadingLayoutConstraint = tableView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: contentView.topAnchor),
            detailLeadingLayoutConstraint,
            tableView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
        ])
        
        walletBalanceLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(walletBalanceLabel)
        NSLayoutConstraint.activate([
            walletBalanceLabel.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 8),
            walletBalanceLabel.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            walletBalanceLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: walletBalanceLabel.bottomAnchor),
        ])
    }
    
}
