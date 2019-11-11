//
//  MnemonicCollectionViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-1-17.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SearchTextField

final public class MnemonicCollectionViewCell: UICollectionViewCell {

    public static let height: CGFloat = 40.0

    public let cardView = UIView()
    public let wordTextField = SearchTextField()

    public override func prepareForReuse() {
        super.prepareForReuse()
        wordTextField.textColor = .black
        cardView.backgroundColor = .white
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        cardView.layer.masksToBounds = true
        cardView.backgroundColor = .white

        wordTextField.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(wordTextField)
        NSLayoutConstraint.activate([
            wordTextField.topAnchor.constraint(equalTo: cardView.topAnchor),
            wordTextField.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            wordTextField.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            wordTextField.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
        ])

        wordTextField.textAlignment = .center
        wordTextField.font = FontFamily.SFProDisplay.regular.font(size: 15.0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        cardView.layer.cornerRadius = 5

        let cornerRadii = CGSize(width: 5, height: 5)
        layer.addSketchShadow(color: .black, alpha: 0.06, x: 0, y: 1, blur: 4, spread: 0, roundedRect: bounds, byRoundingCorners: .allCorners, cornerRadii: cornerRadii)    }

}

extension MnemonicCollectionViewCell {

    public override var isSelected: Bool {
        didSet {
            wordTextField.textColor = isSelected ? UIColor.black.withAlphaComponent(0.1) : .black
            cardView.backgroundColor = isSelected ? UIColor.white.withAlphaComponent(0.6) : .white
        }
    }

    public override var isHighlighted: Bool {
        didSet {
            wordTextField.textColor = isHighlighted ? UIColor.black.withAlphaComponent(0.1) : .black
            cardView.backgroundColor = isHighlighted ? UIColor.white.withAlphaComponent(0.6) : .white
        }
    }

}


