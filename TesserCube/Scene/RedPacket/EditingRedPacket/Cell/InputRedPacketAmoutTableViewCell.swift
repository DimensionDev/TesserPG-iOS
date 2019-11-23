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

final class InputRedPacketAmoutTableViewCell: UITableViewCell, LeftDetailStyle {
    
    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumIntegerDigits = 1
        formatter.maximumFractionDigits = 9 // percision to 1gwei
        formatter.groupingSeparator = ""
        return formatter
    }()
        
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
    lazy var amountTextField: UITextField = {
        let textField = UITextField()
        textField.keyboardType = .decimalPad
        textField.placeholder = self.decimalFormatter.string(from: self.minimalAmount.value as NSNumber)
        return textField
    }()
    let coinCurrencyUnitLabel: UILabel = {
        let label = UILabel()
        label.text = "ETH"
        label.textColor = ._secondaryLabel
        return label
    }()
    
    let disposeBag = DisposeBag()
    
    // Input
    let minimalAmount = BehaviorRelay(value: Decimal(0.001))     // 0.001 ETH
    
    // Output
    let amount = BehaviorRelay<Decimal>(value: Decimal(0))

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
        
        // Setup amountTextField
        amountTextField.delegate = self
        amountTextField.rx.text.asDriver()
            .drive(onNext: { [weak self] text in
                guard let amountText = text, let decimal = Decimal(string: amountText) else {
                    self?.amount.accept(Decimal(0))
                    return
                }
                
                self?.amount.accept(decimal)
            })
            .disposed(by: disposeBag)
        
        minimalAmount.asDriver()
            .drive(onNext: { [weak self] minimalAmount in
                guard let `self` = self else { return }
                let minimalAmountText = self.decimalFormatter.string(from: minimalAmount as NSNumber)
                
                // Update placeholder
                self.amountTextField.placeholder = minimalAmountText
                
                // Update text if less than min amount value
                if let text = self.amountTextField.text,
                let amount = Decimal(string: text), amount < minimalAmount {
                    self.amountTextField.text = minimalAmountText
                }
            })
            .disposed(by: disposeBag)
        
    }
    
}

// MARK: - UITextFieldDelegate
extension InputRedPacketAmoutTableViewCell: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField === amountTextField else {
            return true
        }
        
        // empty
        if string.isEmpty {
            return true
        }
        
        guard Decimal(string: string) != nil else {
            return false
        }
        
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
            textField.text = decimalFormatter.string(from: minimalAmount.value as NSNumber)
        } else {
            textField.text = decimalFormatter.string(from: decimal as NSNumber)
        }
    }
    
}
