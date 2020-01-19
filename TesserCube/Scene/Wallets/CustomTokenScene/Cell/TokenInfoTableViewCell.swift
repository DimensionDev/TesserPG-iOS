//
//  TokenInfoTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-15.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class TokenInfoTableViewCell: UITableViewCell {
    
    var disposeBag = DisposeBag()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 17)
        label.text = "Title"
        return label
    }()
    let infoTextField: UITextField = {
        let textField = UITextField()
        textField.font = FontFamily.SFProText.regular.font(size: 17)
        textField.placeholder = "…"
        textField.textColor = ._secondaryLabel
        textField.isEnabled = false
        return textField
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension TokenInfoTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        let titleLabelHeightLayoutConstrait = titleLabel.heightAnchor.constraint(equalToConstant: 44)
        titleLabelHeightLayoutConstrait.priority = .defaultHigh
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            titleLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            titleLabelHeightLayoutConstrait,
        ])
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        // Layout detail view
        infoTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(infoTextField)
        NSLayoutConstraint.activate([
            infoTextField.topAnchor.constraint(equalTo: contentView.topAnchor),
            infoTextField.leadingAnchor.constraint(equalToSystemSpacingAfter: titleLabel.trailingAnchor, multiplier: 1.0),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: infoTextField.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: infoTextField.bottomAnchor),
        ])
    }
    
}
