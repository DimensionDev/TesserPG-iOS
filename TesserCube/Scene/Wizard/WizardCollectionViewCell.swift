//
//  WizardCollectionViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-5-7.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

final class WizardCollectionViewCell: UICollectionViewCell {

    var page: WizardCollectionViewController.Page? {
        didSet {
            guard let page = page else {
                titleLabel.text = ""
                detailLabel.text = ""
                return
            }
            titleLabel.text = page.titleText

            let paragraphStyle = NSMutableParagraphStyle() 
            paragraphStyle.lineSpacing = 22 - 17 - (detailLabel.font.lineHeight - detailLabel.font.pointSize)
            paragraphStyle.alignment = .center
            let attributedString = NSMutableAttributedString(string: page.detailText, attributes: [NSAttributedString.Key.paragraphStyle : paragraphStyle])
            detailLabel.attributedText = attributedString
        }
    }

    let imagePlaceholderView: UIView = {
        let placeholder = UIView()
        return placeholder
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProDisplay.regular.font(size: 26)
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    let detailLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 17)
        label.numberOfLines = 0
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

}

extension WizardCollectionViewCell {

    private func _init() {
        imagePlaceholderView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imagePlaceholderView)
        NSLayoutConstraint.activate([
            imagePlaceholderView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor, constant: WizardViewController.imageTopMargin),
            imagePlaceholderView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imagePlaceholderView.heightAnchor.constraint(equalToConstant: WizardViewController.imageWidth),
            imagePlaceholderView.widthAnchor.constraint(equalTo: imagePlaceholderView.heightAnchor, multiplier: 1.0),
        ])

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: imagePlaceholderView.bottomAnchor, constant: WizardViewController.imageBottomMargin),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
        ])

        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(detailLabel)
        NSLayoutConstraint.activate([
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            detailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

}
