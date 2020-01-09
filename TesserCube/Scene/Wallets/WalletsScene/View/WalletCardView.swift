//
//  WalletCardView.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-25.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

final class WalletCardView: UIView {
    
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
    
    let cardView: TCCardView = {
        let cardView = TCCardView()
        cardView.cardBackgroundColor = .systemPurple
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
        label.text = "********************\n********************"
        label.font = FontFamily.SourceCodeProMedium.regular.font(size: 14)
        label.numberOfLines = 2
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
        label.text = "- ETH"
        label.font = WalletCardView.SFAlternativesFormFont
        label.textColor = .white
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension WalletCardView {
    
    private func _init() {
        // - Card
        //  - Header
        //  - Caption
        //  - Balance + BalanceAmount
        cardView.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cardView)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
        ])
        
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(headerLabel)
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: cardView.layoutMarginsGuide.topAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.trailingAnchor),
        ])
        headerLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(captionLabel)
        NSLayoutConstraint.activate([
            captionLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            captionLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor),
            captionLabel.trailingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.trailingAnchor),
        ])
        captionLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        captionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(balanceLabel)
        NSLayoutConstraint.activate([
            balanceLabel.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 8),
            balanceLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor),
            cardView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: balanceLabel.bottomAnchor),
        ])
        balanceLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        balanceLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        balanceAmountLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(balanceAmountLabel)
        NSLayoutConstraint.activate([
            balanceAmountLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: balanceLabel.trailingAnchor, multiplier: 1.0),
            balanceAmountLabel.centerYAnchor.constraint(equalTo: balanceLabel.centerYAnchor),
            balanceAmountLabel.trailingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.trailingAnchor),
        ])
    }
    
}
