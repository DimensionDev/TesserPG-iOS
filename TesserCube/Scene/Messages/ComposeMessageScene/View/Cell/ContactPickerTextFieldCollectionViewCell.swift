//
//  ContactPickerTextFieldCollectionViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-3-26.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit

final class ContactPickerTextFieldCollectionViewCell: UICollectionViewCell {

    static let height: CGFloat = ContactPickerTagCollectionViewCell.tagHeight

    let textField: UITextField = {
        let textField = UITextField()

        return textField
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
        contentView.snp.makeConstraints { maker in
            maker.height.equalTo(ContactPickerTextFieldCollectionViewCell.height)
        }

        contentView.addSubview(textField)
        textField.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
        }
    }

}
