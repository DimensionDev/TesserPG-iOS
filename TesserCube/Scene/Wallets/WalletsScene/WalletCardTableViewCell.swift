//
//  WalletCardTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-8.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

final class WalletCardTableViewCell: UITableViewCell {

    static let SFAlternativesFormFont: UIFont = {
        let descriptor = FontFamily.SFProDisplay.medium.font(size: 17)!.fontDescriptor
        let adjusted = descriptor.addingAttributes(
            [
                UIFontDescriptor.AttributeName.featureSettings: [
                    [
                        UIFontDescriptor.FeatureKey.featureIdentifier: kStylisticAlternativesType,
                        UIFontDescriptor.FeatureKey.typeIdentifier: kStylisticAltOneOnSelector
                    ],
                    [
                        UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType,
                        UIFontDescriptor.FeatureKey.typeIdentifier: kMonospacedNumbersSelector
                    ]
                ]
            ]
        )
        return UIFont(descriptor: adjusted, size: 17.0)
    }()

    static let cardVerticalMargin: CGFloat = 8

    let cardView: TCCardView = {
        let cardView = TCCardView()
        cardView.backgroundColor = .systemPurple
        return cardView
    }()
    let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "****"
        label.font = FontFamily.SFProDisplay.medium.font(size: 20)
        label.textColor = .white
        return label
    }()
    let captionLabel: UILabel = {
        let label = UILabel()
        label.text = "****************"
        label.font = FontFamily.SourceCodeProMedium.regular.font(size: 14)
        label.textColor = .white
        return label
    }()
    let balanceLabel: UILabel = {
        let label = UILabel()
        label.text = "Balance:"
        label.font = FontFamily.SFProDisplay.medium.font(size: 17)
        label.textColor = .white
        return label
    }()
    let balanceAmountLabel: UILabel = {
        let label = UILabel()
        label.text = "0 ETH"
        label.font = WalletCardTableViewCell.SFAlternativesFormFont
        label.textColor = .white
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func _init() {
        // - Card
        //  - Header
        //  - Caption
        //  - Balance + BalanceAmount
        cardView.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: WalletCardTableViewCell.cardVerticalMargin),
            cardView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: WalletCardTableViewCell.cardVerticalMargin),
        ])

        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(headerLabel)
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: cardView.layoutMarginsGuide.topAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.trailingAnchor),
        ])

        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(captionLabel)
        NSLayoutConstraint.activate([
            captionLabel.topAnchor.constraint(equalToSystemSpacingBelow: headerLabel.bottomAnchor, multiplier: 1.0),
            captionLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor),
            captionLabel.trailingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.trailingAnchor),
        ])

        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(balanceLabel)
        NSLayoutConstraint.activate([
            balanceLabel.topAnchor.constraint(equalToSystemSpacingBelow: captionLabel.bottomAnchor, multiplier: 1.0),
            balanceLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor),
            cardView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: balanceLabel.bottomAnchor),
        ])
        balanceLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        balanceAmountLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(balanceAmountLabel)
        NSLayoutConstraint.activate([
            balanceAmountLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: balanceLabel.trailingAnchor, multiplier: 1.0),
            balanceAmountLabel.centerYAnchor.constraint(equalTo: balanceLabel.centerYAnchor),
            balanceAmountLabel.trailingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.trailingAnchor),
        ])
    }

}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct WalletCardTableViewCell_Preview: PreviewProvider {
    static var previews: some View {
        UIViewPreview {
            return WalletCardTableViewCell()
        }
        .previewLayout(.fixed(width: 414, height: 122))
    }
}
#endif
