//
//  SelectRedPacketSenderTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-22.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

final class SelectRedPacketSenderTableViewCell: UITableViewCell, LeftDetailStyle {
    
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
    private(set) lazy var senderTextField: UITextField = {
        let textField = UITextField()
        return textField
    }()
    let dropDownArrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Asset.arrowDropDown24px.image
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
        
        // Bind stepper target & action
//        shareStepper.rx.value.asDriver()
//            .map { Int($0) }
//            .drive(share)
//            .disposed(by: disposeBag)
//
//        // Setup Stepper label
//        share.asDriver()
//            .map { String($0) }
//            .drive(shareLabel.rx.text)
//            .disposed(by: disposeBag)
    }
    
}
