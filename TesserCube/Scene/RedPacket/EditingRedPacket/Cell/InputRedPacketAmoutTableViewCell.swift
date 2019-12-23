//
//  InputRedPacketAmoutTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-22.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class InputRedPacketAmoutTableViewCell: UITableViewCell {
        
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 17)
        label.text = "Amount"
        return label
    }()
    
    lazy var amountTextField: UITextField = {
        let textField = UITextField()
        textField.font = FontFamily.SFProText.regular.font(size: 17)
        textField.keyboardType = .decimalPad
        textField.placeholder = NumberFormatter.decimalFormatterForETH.string(from: self.minimalAmount.value as NSNumber)
        return textField
    }()
    
    let coinCurrencyUnitLabel: UILabel = {
        let label = UILabel()
        label.text = "ETH"
        label.textColor = ._secondaryLabel
        return label
    }()
    
    var disposeBag = DisposeBag()
    
    // Input
    let minimalAmount = BehaviorRelay(value: RedPacketService.redPacketMinAmount)
    
    // Output
    let amount = BehaviorRelay<Decimal>(value: Decimal(0))
    
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
    
        amountTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(amountTextField)
        NSLayoutConstraint.activate([
            amountTextField.topAnchor.constraint(equalTo: contentView.topAnchor),
            amountTextField.leadingAnchor.constraint(equalToSystemSpacingAfter: titleLabel.trailingAnchor, multiplier: 1.0),
            contentView.bottomAnchor.constraint(equalTo: amountTextField.bottomAnchor),
        ])
        
        coinCurrencyUnitLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(coinCurrencyUnitLabel)
        NSLayoutConstraint.activate([
            coinCurrencyUnitLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            coinCurrencyUnitLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: amountTextField.trailingAnchor, multiplier: 1.0),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: coinCurrencyUnitLabel.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: coinCurrencyUnitLabel.bottomAnchor),
        ])
        coinCurrencyUnitLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        coinCurrencyUnitLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        
        // Setup amountTextField
        amountTextField.delegate = self

        minimalAmount.asDriver()
            .drive(onNext: { [weak self] minimalAmount in
                guard let `self` = self else { return }
                let minimalAmountText = NumberFormatter.decimalFormatterForETH.string(from: minimalAmount as NSNumber)

                // Update placeholder
                self.amountTextField.placeholder = minimalAmountText

                // Update text if less than min amount value
                if let text = self.amountTextField.text,
                let amount = Decimal(string: text), amount < minimalAmount {
                    self.amountTextField.text = minimalAmountText
                    self.amount.accept(minimalAmount)
                } else {
                    // do nothing
                }
            })
            .disposed(by: disposeBag)
    }
    
}

extension InputRedPacketAmoutTableViewCell {
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected {
            amountTextField.becomeFirstResponder()
        }
    }
    
}

// MARK: - UITextFieldDelegate
extension InputRedPacketAmoutTableViewCell: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField === amountTextField else {
            return true
        }
        
        guard let currentText = textField.text else {
            return false
        }
        
        guard let stringRange = Range(range, in: currentText) else {
            return false
        }
        
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)

        // empty
        if updatedText.isEmpty {
            return true
        }
        
        guard let amountValue = Decimal(string: updatedText) else {
            return false
        }
        
        amount.accept(amountValue)
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard textField === amountTextField else {
            return
        }
        
        guard let text = textField.text, let decimal = Decimal(string: text) else {
            return
        }
        
        if decimal < minimalAmount.value {
            textField.text = NumberFormatter.decimalFormatterForETH.string(from: minimalAmount.value as NSNumber)
            amount.accept(minimalAmount.value)
        } else {
            textField.text = NumberFormatter.decimalFormatterForETH.string(from: decimal as NSNumber)
            amount.accept(decimal)
        }
    }
    
}
