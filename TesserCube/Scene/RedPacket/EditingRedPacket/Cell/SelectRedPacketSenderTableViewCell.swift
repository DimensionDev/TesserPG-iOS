//
//  SelectRedPacketSenderTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-22.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class SelectRedPacketSenderViewModel: NSObject {
    
    let disposeBag = DisposeBag()
    
    // Input
    let keys: BehaviorRelay<[TCKey]>
    let selectedKey = BehaviorRelay<TCKey?>(value: nil)
    
    // Output
    let senderName: Driver<String>
    let senderShortID: Driver<String>
    
    override init() {
        let secretKeys = ProfileService.default.keys.value.filter { key in
            return key.hasSecretKey && key.hasPublicKey
        }
        keys = BehaviorRelay<[TCKey]>(value: secretKeys)

        ProfileService.default.keys.asDriver()
            .map { $0.filter { $0.hasSecretKey && $0.hasPublicKey } }
            .drive(keys)
            .disposed(by: disposeBag)
        
        senderName = selectedKey.asDriver()
            .map { $0?.name ?? L10n.Common.Label.nameNone }
        senderShortID = selectedKey.asDriver()
            .map { $0?.shortIdentifier ?? "" }
        
        super.init()
        
        selectedKey.accept(keys.value.first)
    }
}

// MARK: - UIPickerViewDataSource
extension SelectRedPacketSenderViewModel: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return keys.value.count + 1 // [none]
    }
    
}


final class SelectRedPacketSenderTableViewCell: UITableViewCell, LeftDetailStyle {
    
    let disposeBag = DisposeBag()
    let viewModel = SelectRedPacketSenderViewModel()
    
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
    private let senderPickerView: UIPickerView = {
        let pickerView = UIPickerView()
        return pickerView
    }()
    private(set) lazy var senderTextField: UITextField = {
        let textField = UITextField()
        textField.inputView = senderPickerView
        return textField
    }()
    let dropDownArrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Asset.arrowDropDown24px.image
        imageView.tintColor = ._secondaryLabel
        return imageView
    }()
    
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
        senderTextField.translatesAutoresizingMaskIntoConstraints = false
        detailView.addSubview(senderTextField)
        NSLayoutConstraint.activate([
            senderTextField.topAnchor.constraint(equalToSystemSpacingBelow: detailView.topAnchor, multiplier: 1.0),
            senderTextField.leadingAnchor.constraint(equalToSystemSpacingAfter: detailView.leadingAnchor, multiplier: 1.0),
            detailView.bottomAnchor.constraint(equalToSystemSpacingBelow: senderTextField.bottomAnchor, multiplier: 1.0),
        ])
        
        dropDownArrowImageView.translatesAutoresizingMaskIntoConstraints = false
        detailView.addSubview(dropDownArrowImageView)
        NSLayoutConstraint.activate([
            dropDownArrowImageView.topAnchor.constraint(equalToSystemSpacingBelow: detailView.topAnchor, multiplier: 1.0),
            dropDownArrowImageView.leadingAnchor.constraint(equalToSystemSpacingAfter: senderTextField.trailingAnchor, multiplier: 1.0),
            detailView.trailingAnchor.constraint(equalToSystemSpacingAfter: dropDownArrowImageView.trailingAnchor, multiplier: 1.0),
            detailView.bottomAnchor.constraint(equalToSystemSpacingBelow: dropDownArrowImageView.bottomAnchor, multiplier: 1.0),
        ])
        dropDownArrowImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        dropDownArrowImageView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        // Bind picker data
        senderPickerView.delegate = self
        senderPickerView.dataSource = viewModel

        viewModel.keys.asDriver()
            .drive(onNext: { [weak self] _ in
                self?.senderPickerView.reloadAllComponents()
            })
            .disposed(by: disposeBag)
        viewModel.senderName.drive(senderTextField.rx.text).disposed(by: disposeBag)
    }
    
}

// MARK: - UIPickerViewDelegate
extension SelectRedPacketSenderTableViewCell: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true

        switch row {
        case 0..<viewModel.keys.value.count:
            let key = viewModel.keys.value[row]
            label.text = [key.name, "(\(key.shortIdentifier))"]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")

        default:
            label.text = L10n.Common.Label.nameNone

        }

        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard row < viewModel.keys.value.count else {
            viewModel.selectedKey.accept(nil)
            return
        }

        let key =  viewModel.keys.value[row]
        viewModel.selectedKey.accept(key)
    }
    
}
