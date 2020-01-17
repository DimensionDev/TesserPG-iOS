//
//  SelectWalletTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-22.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class SelectWalletTableViewCell: UITableViewCell {
    
    var disposeBag = DisposeBag()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 17)
        label.text = "Wallet"
        return label
    }()
    let walletPickerView: UIPickerView = {
        let pickerView = UIPickerView()
        return pickerView
    }()
    private(set) lazy var walletTextField: UITextField = {
        let textField = ReadOnlyTextField()
        #if TARGET_IS_KEYBOARD
        // User touching UITextField will trigger `textDidChange` callback, which makes our keyboard reset all the custom views
        textField.isUserInteractionEnabled = false
        #endif
        
        textField.font = FontFamily.SFProText.regular.font(size: 17)
        textField.inputView = walletPickerView
        textField.text = "[None]"
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
        
        walletTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(walletTextField)
        NSLayoutConstraint.activate([
            walletTextField.topAnchor.constraint(equalTo: contentView.topAnchor),
            walletTextField.leadingAnchor.constraint(equalToSystemSpacingAfter: titleLabel.trailingAnchor, multiplier: 1.0),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: walletTextField.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: walletTextField.bottomAnchor),
        ])
    }
    
}
