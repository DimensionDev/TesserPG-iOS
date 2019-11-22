//
//  InputRedPacketAmoutTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-22.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

final class InputRedPacketAmoutTableViewCell: UITableViewCell, LeftDetailStyle {
        
    let titleLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    var detailLeadingLayoutConstraint: NSLayoutConstraint!
    
    let detailView: UIView = {
        let view = UIView()
        view.backgroundColor = ._secondarySystemGroupedBackground
        return view
    }()
    let amountTextField: UITextField = {
        let textField = UITextField()
        textField.keyboardType = .decimalPad
        textField.placeholder = "0.0"
        return textField
    }()
    let coinCurrencyUnitLabel: UILabel = {
        let label = UILabel()
        label.text = "ETH"
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
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        detailView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(detailView)
        detailLeadingLayoutConstraint = detailView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor)
        NSLayoutConstraint.activate([
            detailView.topAnchor.constraint(equalTo: contentView.topAnchor),
            detailLeadingLayoutConstraint,
            detailView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            detailView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        // Layout detail view
        amountTextField.translatesAutoresizingMaskIntoConstraints = false
        detailView.addSubview(amountTextField)
        NSLayoutConstraint.activate([
            amountTextField.topAnchor.constraint(equalToSystemSpacingBelow: detailView.topAnchor, multiplier: 1.0),
            amountTextField.leadingAnchor.constraint(equalToSystemSpacingAfter: detailView.leadingAnchor, multiplier: 1.0),
            detailView.bottomAnchor.constraint(equalToSystemSpacingBelow: amountTextField.bottomAnchor, multiplier: 1.0),
        ])
        
        coinCurrencyUnitLabel.translatesAutoresizingMaskIntoConstraints = false
        detailView.addSubview(coinCurrencyUnitLabel)
        NSLayoutConstraint.activate([
            coinCurrencyUnitLabel.topAnchor.constraint(equalToSystemSpacingBelow: detailView.topAnchor, multiplier: 1.0),
            coinCurrencyUnitLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: amountTextField.trailingAnchor, multiplier: 1.0),
            detailView.trailingAnchor.constraint(equalToSystemSpacingAfter: coinCurrencyUnitLabel.trailingAnchor, multiplier: 1.0),
            detailView.bottomAnchor.constraint(equalToSystemSpacingBelow: coinCurrencyUnitLabel.bottomAnchor, multiplier: 1.0),
        ])
        coinCurrencyUnitLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        coinCurrencyUnitLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }
    
}
