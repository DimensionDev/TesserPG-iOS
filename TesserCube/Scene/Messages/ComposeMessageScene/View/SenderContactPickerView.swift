//
//  SenderContactPickerView.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-3-26.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import KeychainAccess

final class SenderContactPickerViewModel: NSObject {
    
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
extension SenderContactPickerViewModel: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return keys.value.count + 1 // [none]
    }
    
}

final class SenderContactPickerView: UIView {
    
    let disposeBag = DisposeBag()

    static let leadingMargin: CGFloat = 20
    static let verticalMargin: CGFloat = 6

    private let paddingView = UIView()
    
    let viewModel = SenderContactPickerViewModel()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.lightTextGrey.color
        label.font = FontFamily.SFProText.regular.font(size: 15)
        return label
    }()
    
    let senderPickerView: UIPickerView = {
        let pickerView = UIPickerView()
        return pickerView
    }()
    
    lazy var senderTextField: UITextField = {
        let textField = UITextField()
        textField.inputView = senderPickerView
        textField.font = FontFamily.SFProDisplay.regular.font(size: 16)
        return textField
    }()

    let shortIDLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SourceCodeProMedium.regular.font(size: 14)
        label.textColor = Asset.shortIdBlue.color
        label.textAlignment = .right
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _init()
    }

    private func _init() {
        backgroundColor = .clear
        layoutMargins = UIEdgeInsets(top: 8, left: RecipientContactPickerView.leadingMargin, bottom: 8, right: 20)

        paddingView.isHidden = true
        addSubview(paddingView)
        paddingView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.equalToSuperview()
            maker.height.equalTo(ContactPickerTagCollectionViewCell.tagHeight + 2 * RecipientContactPickerView.verticalMargin).priority(999)
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(layoutMarginsGuide)
            maker.centerY.equalTo(paddingView.snp.centerY)
        }
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        addSubview(senderTextField)
        senderTextField.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.trailing).offset(14)
            maker.top.bottom.equalToSuperview()
        }
        senderTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)

        addSubview(shortIDLabel)
        shortIDLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(senderTextField.snp.trailing)
            maker.centerY.equalTo(senderTextField.snp.centerY)
            maker.trailing.equalTo(snp.trailing).offset(-11)
        }
        shortIDLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        shortIDLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let separatorView = UIView()
        addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.bottom.equalTo(paddingView.snp.bottom)
            maker.leading.equalTo(snp.leadingMargin)
            maker.trailing.bottom.equalToSuperview()
            maker.height.equalTo(0.3)
        }

        separatorView.backgroundColor = Asset.separator.color
        senderPickerView.delegate = self
        senderPickerView.dataSource = viewModel
        
        viewModel.keys.asDriver()
            .drive(onNext: { [weak self] _ in
                self?.senderPickerView.reloadAllComponents()
            })
            .disposed(by: disposeBag)
        viewModel.senderName.drive(senderTextField.rx.text).disposed(by: disposeBag)
        viewModel.senderShortID.drive(shortIDLabel.rx.text).disposed(by: disposeBag)
    }

}

// MARK: - UIPickerViewDelegate
extension SenderContactPickerView: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true

        switch row {
        case 0..<viewModel.keys.value.count:
            let key =  viewModel.keys.value[row]
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
