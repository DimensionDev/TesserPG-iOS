//
//  RedPacketCardTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-23.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift

final class RedPacketCardTableViewCell: UITableViewCell {

    var disposeBag = DisposeBag()

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
        cardView.cardBackgroundColor = .systemRed
        return cardView
    }()
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProDisplay.bold.font(size: 14)
        label.textColor = .systemYellow
        return label
    }()
    let emailLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProDisplay.regular.font(size: 14)
        label.textColor = .systemYellow
        return label
    }()
    let redPacketStatusLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProDisplay.regular.font(size: 22)
        label.textColor = .systemYellow
        return label
    }()
    let redPacketDetailLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 14)
        label.textColor = .systemYellow
        return label
    }()
    let createdDateLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 14)
        label.textColor = .systemYellow
        return label
    }()
    let indicatorLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 14)
        label.textColor = .systemYellow
        label.textAlignment = .right
        return label
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
    }

    private func _init() {
        backgroundColor = .clear
        
        // - Card
        //  - Name | Mail
        //  - RedPacketStatus
        //  - RedPacketDetail
        //  - CreatedDate | Indicator
        cardView.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: RedPacketCardTableViewCell.cardVerticalMargin),
            cardView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: RedPacketCardTableViewCell.cardVerticalMargin),
        ])
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: cardView.layoutMarginsGuide.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor),
        ])
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(emailLabel)
        NSLayoutConstraint.activate([
            emailLabel.firstBaselineAnchor.constraint(equalTo: nameLabel.firstBaselineAnchor),
            emailLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 4),
            emailLabel.trailingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.trailingAnchor),
        ])

        redPacketStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(redPacketStatusLabel)
        NSLayoutConstraint.activate([
            redPacketStatusLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            redPacketStatusLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor),
            redPacketStatusLabel.trailingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.trailingAnchor),
        ])
        redPacketStatusLabel.setContentHuggingPriority(.defaultLow, for: .vertical)

        redPacketDetailLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(redPacketDetailLabel)
        NSLayoutConstraint.activate([
            redPacketDetailLabel.topAnchor.constraint(equalTo: redPacketStatusLabel.bottomAnchor, constant: 8),
            redPacketDetailLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor),
            redPacketDetailLabel.trailingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.trailingAnchor),
        ])

        createdDateLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(createdDateLabel)
        NSLayoutConstraint.activate([
            createdDateLabel.topAnchor.constraint(equalTo: redPacketDetailLabel.bottomAnchor),
            createdDateLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor),
            cardView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: createdDateLabel.bottomAnchor),
        ])
        
        indicatorLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(indicatorLabel)
        NSLayoutConstraint.activate([
            indicatorLabel.firstBaselineAnchor.constraint(equalTo: createdDateLabel.firstBaselineAnchor),
            indicatorLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: createdDateLabel.trailingAnchor, multiplier: 1.0),
            indicatorLabel.trailingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.trailingAnchor),
        ])
        indicatorLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        nameLabel.text = "Name"
        emailLabel.text = "(name@mail.com)"
        redPacketStatusLabel.text = "Outgoing Red Packet"
        redPacketDetailLabel.text = "Giving 0.2 ETH / 3 shares"
        createdDateLabel.text = "2 hr ago created"
        indicatorLabel.text = "Publishing…"

        // Setup appearance
        clipsToBounds = false
        selectionStyle = .none
    }

}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct RedPacketCardTableViewCell_Preview: PreviewProvider {
    static var previews: some View {
        UIViewPreview {
            return RedPacketCardTableViewCell()
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif
