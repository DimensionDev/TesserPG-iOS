//
//  ContactPickerTagCollectionViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-3-26.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit
import DeepDiff

extension KeyBridge: DiffAware {

    var diffId: Int {
        return "\(contactID ?? -1):\(name):\(longIdentifier)".hashValue
    }

    static func compareContent(_ a: KeyBridge, _ b: KeyBridge) -> Bool {
        return a.diffId == b.diffId
    }

}

// Delegate
protocol ContactPickerTagCollectionViewCellDelegate: class {
    func contactPickerTagCollectionViewCell(_ cell: ContactPickerTagCollectionViewCell, didDeleteBackward: Void)
}

// TODO: add done toolbar on keyboard when become first responder
final class ContactPickerTagCollectionViewCell: UICollectionViewCell {

    static let tagHeight: CGFloat = 32
    
    private var _isSelected = false
    weak var delegate: ContactPickerTagCollectionViewCellDelegate?

    let corneredBackgroundView: UIView = {
        let view = UIView()
        if #available(iOS 13.0, *) {
            view.backgroundColor = .secondarySystemBackground
        } else {
            // Fallback on earlier versions
            view.backgroundColor = Asset.tagBackgroundGrey.color
        }
        return view
    }()

    let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Label"
        label.font = FontFamily.SFProDisplay.regular.font(size: 16)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        if #available(iOS 13.0, *) {
            label.textColor = .label
        } else {
            // Fallback on earlier versions
            label.textColor = .black
        }
        return label
    }()

    let shortIDLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SourceCodeProMedium.regular.font(size: 11)
        label.textColor = .systemGreen
        label.numberOfLines = 2
        return label
    }()

    var shortID: String {
        get {
            return shortIDLabel.text ?? ""
        }
        set {
            let style = NSMutableParagraphStyle()
            style.lineHeightMultiple = 0.75
            let attributedString = NSMutableAttributedString(string: newValue)
            attributedString.addAttributes([NSAttributedString.Key.paragraphStyle : style], range: NSRange(location: 0, length: attributedString.length))
            shortIDLabel.attributedText = attributedString
        }
    }

    var isInvalid = false {
        didSet {
            if isInvalid {
                if #available(iOS 13, *) {
                    corneredBackgroundView.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .systemRed : Asset.tagBackgroundPink.color
                    shortIDLabel.textColor = traitCollection.userInterfaceStyle == .dark ? Asset.tagBackgroundPink.color : .systemRed
                } else {
                    corneredBackgroundView.backgroundColor = Asset.tagBackgroundPink.color
                    shortIDLabel.textColor = .systemRed
                }
            } else {
                if #available(iOS 13.0, *) {
                    corneredBackgroundView.backgroundColor = .secondarySystemBackground
                } else {
                    // Fallback on earlier versions
                    corneredBackgroundView.backgroundColor = Asset.tagBackgroundGrey.color
                }
                shortIDLabel.textColor = .systemGreen
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        _isSelected = false
        isInvalid = false
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _init()
    }

    private func _init() {
        contentView.addSubview(corneredBackgroundView)
        corneredBackgroundView.snp.makeConstraints { maker in
            maker.top.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(32).priority(999)
        }

        corneredBackgroundView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(14)
            maker.centerY.equalToSuperview()
        }
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        corneredBackgroundView.addSubview(shortIDLabel)
        shortIDLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(nameLabel.snp.trailing).offset(8)
            maker.centerY.equalToSuperview().offset(1.5)
            maker.trailing.equalToSuperview().offset(-14)
        }
        shortIDLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        corneredBackgroundView.layer.masksToBounds = true
        corneredBackgroundView.layer.cornerRadius = ContactPickerTagCollectionViewCell.tagHeight * 0.5
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if isInvalid {
            // reload color
            let value = isInvalid
            isInvalid = value
        }
    }

}

extension ContactPickerTagCollectionViewCell {
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        let status = super.resignFirstResponder()
        isSelected = false
        return status
    }
    
    override func becomeFirstResponder() -> Bool {
        let status = super.becomeFirstResponder()
        isSelected = true
        return status
    }
    
    override var isSelected: Bool {
        didSet {
            guard _isSelected != isSelected else {
                return
            }
            _isSelected = isSelected
            
            if isSelected {
                if !isFirstResponder { becomeFirstResponder() }
                UIView.animate(withDuration: 0.33) {
                    self.corneredBackgroundView.backgroundColor = .systemBlue
                    self.nameLabel.textColor = .white
                    self.shortIDLabel.textColor = .white
                }
            } else {
                if isFirstResponder { resignFirstResponder() }
                UIView.animate(withDuration: 0.33) {
                    if #available(iOS 13.0, *) {
                        self.corneredBackgroundView.backgroundColor = .secondarySystemBackground
                        self.nameLabel.textColor = .label
                    } else {
                        // Fallback on earlier versions
                        self.corneredBackgroundView.backgroundColor = Asset.tagBackgroundGrey.color
                        self.nameLabel.textColor = .black
                    }

                    self.shortIDLabel.textColor = .systemGreen
                    let isInvalid = self.isInvalid
                    self.isInvalid = isInvalid
                }
            }
        }   // end didSet
    }
    
}

// MARK: - UIKeyInput
extension ContactPickerTagCollectionViewCell: UIKeyInput {
    
    var hasText: Bool {
        return true
    }
    
    func insertText(_ text: String) {
        // Do nothing
    }
    
    func deleteBackward() {
        delegate?.contactPickerTagCollectionViewCell(self, didDeleteBackward: ())
    }
    
    var autocorrectionType: UITextAutocorrectionType {
        get { return .no }
        set { /* do nothing */ }
    }
}
