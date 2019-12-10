//
//  InputRedPacketMessageTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-10.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class InputRedPacketMessageTableViewCell: UITableViewCell {
    
    var disposeBag = DisposeBag()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 17)
        label.text = "Message"
        return label
    }()
    
    let messageTextField: UITextField = {
        let textField = UITextField()
        textField.font = FontFamily.SFProText.regular.font(size: 17)
        textField.placeholder = "Message"
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
    
    private func _init() {
        selectionStyle = .none
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            titleLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
        ])
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        // Layout detail view
        messageTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(messageTextField)
        NSLayoutConstraint.activate([
            messageTextField.topAnchor.constraint(equalTo: contentView.topAnchor),
            messageTextField.leadingAnchor.constraint(equalToSystemSpacingAfter: titleLabel.trailingAnchor, multiplier: 1.0),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: messageTextField.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: messageTextField.bottomAnchor),
        ])
    }
    
}

extension InputRedPacketMessageTableViewCell {
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected {
            messageTextField.becomeFirstResponder()
        }
    }
    
}
