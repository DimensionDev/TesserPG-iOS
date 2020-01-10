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

final class SelectWalletViewModel: NSObject {
    
    let disposeBag = DisposeBag()
    
    // Input
    let walletModels = BehaviorRelay<[WalletModel]>(value: [])
    
    // Output
    let selectWalletModel = BehaviorRelay<WalletModel?>(value: nil)
    let selectWalletName = BehaviorRelay(value: "")
    
    override init() {
        super.init()
        
        // Select first when data load
        walletModels.asDriver()
            .map { $0.first }
            .drive(selectWalletModel)
            .disposed(by: disposeBag)
        
        selectWalletModel.asDriver()
            .map { walletModel in
                guard let walletModel = walletModel else {
                    return L10n.Common.Label.nameNone
                }
                
                return "Wallet \(walletModel.address.prefix(6))"
            }
            .drive(selectWalletName)
            .disposed(by: disposeBag)
    }
    
}

// MARK: - SelectWalletViewModel
extension SelectWalletViewModel: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return walletModels.value.isEmpty ? 1 : walletModels.value.count
    }
    
}

final class SelectWalletTableViewCell: UITableViewCell {
    
    var disposeBag = DisposeBag()
    let viewModel = SelectWalletViewModel()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 17)
        label.text = "Wallet"
        return label
    }()
    private let walletPickerView: UIPickerView = {
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
        
        walletPickerView.delegate = self
        walletPickerView.dataSource = viewModel
        
        viewModel.walletModels.asDriver()
            .drive(onNext: { [weak self] _ in
                self?.walletPickerView.reloadAllComponents()
            })
            .disposed(by: viewModel.disposeBag)
        viewModel.selectWalletName.asDriver()
            .drive(walletTextField.rx.text)
            .disposed(by: viewModel.disposeBag)
    }
    
}

// MARK: - UIPickerViewDelegate
extension SelectWalletTableViewCell: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        
        switch row {
        case 0..<viewModel.walletModels.value.count:
            let walletModel = viewModel.walletModels.value[row]
            label.text = "Wallet \(walletModel.address.prefix(6))"
            
        default:
            label.text = L10n.Common.Label.nameNone
        }
        
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard row < viewModel.walletModels.value.count else {
            viewModel.selectWalletModel.accept(nil)
            return
        }
        
        let walletModel = viewModel.walletModels.value[row]
        viewModel.selectWalletModel.accept(walletModel)
    }
    
}
