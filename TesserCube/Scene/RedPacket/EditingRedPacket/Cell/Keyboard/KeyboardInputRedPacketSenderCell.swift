//
//  KeyboardInputRedPacketSenderCell.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 1/14/20.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class KeyboardInputRedPacketSenderCell: UITableViewCell {
    
    var disposeBag = DisposeBag()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 17)
        label.text = "My Name"
        return label
    }()
    
    lazy var nameTextField: KeyboardInputView = {
        let inputView = KeyboardInputView(frame: .zero)
        inputView.inputTextField.textFont = FontFamily.SFProText.regular.font(size: 17)
        inputView.inputTextField.repositionCursor()
        inputView.inputTextField.placeholder = "Name"
        return inputView
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
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameTextField)
        NSLayoutConstraint.activate([
            nameTextField.topAnchor.constraint(equalTo: contentView.topAnchor),
            nameTextField.leadingAnchor.constraint(equalToSystemSpacingAfter: titleLabel.trailingAnchor, multiplier: 1.0),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: nameTextField.bottomAnchor),
        ])
    }
    
}

extension KeyboardInputRedPacketSenderCell {
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        nameTextField.inputTextField.textFieldIsSelected = selected
    }
}
