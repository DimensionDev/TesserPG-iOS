//
//  InputRedPacketShareTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-22.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class InputRedPacketShareTableViewCell: UITableViewCell {
        
    let disposeBag = DisposeBag()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 17)
        label.text = "Shares"
        return label
    }()
    
    let shareTextField: UITextField = {
        let textField = UITextField()
        textField.font = FontFamily.SFProText.regular.font(size: 17)
        textField.text = "1"
        textField.placeholder = "1"
        textField.keyboardType = .numberPad
        #if TARGET_IS_KEYBOARD
        // User touching UITextField will trigger `textDidChange` callback, which makes our keyboard reset all the custom views
        textField.isUserInteractionEnabled = false
        #endif
        return textField
    }()
    
    let shareStepper: UIStepper = {
        let stepper = UIStepper()
        stepper.minimumValue = 1
        stepper.maximumValue = 100
        stepper.stepValue = 1
        stepper.value = 1
        return stepper
    }()
    
    // Output
    let share = BehaviorRelay(value: 1)

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
        
        shareTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(shareTextField)
        NSLayoutConstraint.activate([
            shareTextField.topAnchor.constraint(equalTo: contentView.topAnchor),
            shareTextField.leadingAnchor.constraint(equalToSystemSpacingAfter: titleLabel.trailingAnchor, multiplier: 1.0),
            contentView.bottomAnchor.constraint(equalTo: shareTextField.bottomAnchor),
        ])
        
        shareStepper.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(shareStepper)
        NSLayoutConstraint.activate([
            shareStepper.topAnchor.constraint(equalToSystemSpacingBelow: contentView.topAnchor, multiplier: 1.0),
            shareStepper.leadingAnchor.constraint(equalToSystemSpacingAfter: shareTextField.trailingAnchor, multiplier: 1.0),
            contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: shareStepper.trailingAnchor, multiplier: 1.0),
            contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: shareStepper.bottomAnchor, multiplier: 1.0),
        ])
        shareStepper.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        shareStepper.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        // Setup text field
        shareTextField.delegate = self
        shareTextField.rx.text.orEmpty.asDriver()
            .map { $0.isEmpty ? "1" : "" }
            .drive(onNext: { [weak self] placeholder in
                self?.shareTextField.placeholder = placeholder
            })
            .disposed(by: disposeBag)

        // Setup Stepper
        shareStepper.rx.value.asDriver()
            .map { Int($0) }
            .drive(share)
            .disposed(by: disposeBag)
        
        // Bind share to text field
        share.asDriver()
            .distinctUntilChanged()
            .map { String($0) }
            // .debug()
            .drive(onNext: { text in
                DispatchQueue.main.async { [weak self] in
                    self?.shareTextField.text = text
                }
            })
            .disposed(by: disposeBag)
    }
    
}

// MARK: - UITextFieldDelegate
extension InputRedPacketShareTableViewCell: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField === shareTextField else {
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
            share.accept(1)
            shareStepper.value = 1
            return true
        }
        
        guard let shareValue = Int(updatedText) else {
            return false
        }
        
        guard shareValue > 0 else {
            return false
        }
        
        guard shareValue <= 100 else {
            share.accept(100)
            shareStepper.value = 100
            // Use defer to prevent UITextField internal state issue
            defer {
                textField.text = "100"
            }
            
            // return false to prevent change
            return false
        }
    
        // Update stepper value when editing text field
        share.accept(shareValue)
        shareStepper.value = Double(shareValue)
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard textField === shareTextField else {
            return
        }
        
        guard let text = textField.text, !text.isEmpty else {
            share.accept(1)
            shareStepper.value = Double(1)
            return
        }
    }
    
}
