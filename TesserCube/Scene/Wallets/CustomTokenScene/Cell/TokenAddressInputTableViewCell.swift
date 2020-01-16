//
//  TokenAddressInputTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-15.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class TokenAddressInputTableViewCell: UITableViewCell {
    
    var disposeBag = DisposeBag()
    
    let addressTextField: UITextField = {
        let textField = UITextField()
        textField.font = FontFamily.SFProText.regular.font(size: 17)
        textField.placeholder = "0xdac…"
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

extension TokenAddressInputTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        
        addressTextField.translatesAutoresizingMaskIntoConstraints = false
        let addressTextFieldHeightLayoutConstrait = addressTextField.heightAnchor.constraint(equalToConstant: 44)
        addressTextFieldHeightLayoutConstrait.priority = .defaultHigh
        contentView.addSubview(addressTextField)
        NSLayoutConstraint.activate([
            addressTextField.topAnchor.constraint(equalTo: contentView.topAnchor),
            addressTextField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: addressTextField.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: addressTextField.bottomAnchor),
            addressTextFieldHeightLayoutConstrait,
        ])
    }
    
}

extension TokenAddressInputTableViewCell {
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            addressTextField.becomeFirstResponder()
        }
    }
    
}
