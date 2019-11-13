//
//  PasswordTextFieldTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-6.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift

final public class PasswordTextFieldTableViewCell: UITableViewCell {

    let passphraseTextField = UITextField()

    var disposeBag = DisposeBag()

    public override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        passphraseTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(passphraseTextField)
        NSLayoutConstraint.activate([
            passphraseTextField.topAnchor.constraint(equalTo: contentView.topAnchor),
            passphraseTextField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            passphraseTextField.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            passphraseTextField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ])
        let passphraseTextFieldHeight = passphraseTextField.heightAnchor.constraint(equalToConstant: 44)
        passphraseTextFieldHeight.priority = .defaultHigh
        passphraseTextFieldHeight.isActive = true

        passphraseTextField.font = .systemFont(ofSize: 17.0)
        passphraseTextField.isSecureTextEntry = true
        passphraseTextField.keyboardType = .asciiCapable
        passphraseTextField.returnKeyType = .done
        passphraseTextField.autocorrectionType = .no
        passphraseTextField.autocapitalizationType = .none
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension PasswordTextFieldTableViewCell {

    override public func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            passphraseTextField.becomeFirstResponder()
        }
    }

}
