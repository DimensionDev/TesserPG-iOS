//
//  RedPacketClaimerTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-27.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

final class RedPacketClaimerTableViewCell: UITableViewCell {
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 17)
        label.textColor = ._label
        return label
    }()
    let addressLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 15)
        label.numberOfLines = 0
        label.textColor = ._secondaryLabel
        return label
    }()
    let amountLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 17)
        label.textColor = ._secondaryLabel
        label.text = "- ETH"
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
    
}

extension RedPacketClaimerTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalToSystemSpacingBelow: contentView.topAnchor, multiplier: 1.0),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
        ])
        
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(addressLabel)
        NSLayoutConstraint.activate([
            addressLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            addressLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: addressLabel.bottomAnchor, multiplier: 1.0),
        ])
        
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(amountLabel)
        NSLayoutConstraint.activate([
            amountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 8),
            amountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: addressLabel.trailingAnchor, constant: 8),
            amountLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: amountLabel.trailingAnchor),
        ])
        amountLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        amountLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        
        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
    }
    
}
