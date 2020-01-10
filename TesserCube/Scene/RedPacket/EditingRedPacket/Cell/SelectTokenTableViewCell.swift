//
//  SelectTokenTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-10.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import UIKit

final class SelectTokenTableViewCell: UITableViewCell {
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 17)
        label.text = "Token"
        return label
    }()
    
    private(set) lazy var tokenNameTextField: UITextField = {
        let textField = ReadOnlyTextField()
        textField.isEnabled = false
        // User touching UITextField will trigger `textDidChange` callback, which makes our keyboard reset all the custom views
        textField.isUserInteractionEnabled = false
        textField.font = FontFamily.SFProText.regular.font(size: 17)
        textField.text = "ETH"
        return textField
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

extension SelectTokenTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        accessoryType = .disclosureIndicator
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            titleLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
        ])
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        tokenNameTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tokenNameTextField)
        NSLayoutConstraint.activate([
            tokenNameTextField.topAnchor.constraint(equalTo: contentView.topAnchor),
            tokenNameTextField.leadingAnchor.constraint(equalToSystemSpacingAfter: titleLabel.trailingAnchor, multiplier: 1.0),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: tokenNameTextField.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: tokenNameTextField.bottomAnchor),
        ])
    }
    
}
