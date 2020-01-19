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
        cardView.cardBackgroundColor = Asset.redPacketCardBackground.color
        return cardView
    }()
    let headerVisualEffectView: UIVisualEffectView = {
        
        let effect: UIBlurEffect
        if #available(iOS 13.0, *) {
            effect = UIBlurEffect(style: .systemMaterial)
        } else {
            effect = UIBlurEffect(style: .regular)
        }
        let visualEffectView = UIVisualEffectView(effect: effect)
        return visualEffectView
    }()
    let headerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.redPacketCardHeaderBackground.color
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.cornerRadius = 10
        return view
    }()
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.semibold.font(size: 14)
        label.textColor = Asset.redPacketCardHeaderLabelTextColor.color
        return label
    }()
    let statusLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.semibold.font(size: 14)
        label.textColor = Asset.redPacketCardHeaderLabelTextColor.color
        return label
    }()
    let logoImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        imageView.layer.cornerRadius = 4
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    let messageLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProDisplay.regular.font(size: 20)
        label.textColor = .white
        return label
    }()
    let detailLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 18)
        label.textColor = .white
        return label
    }()
    let leftFooterLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 14)
        label.textColor = .white
        return label
    }()
    let rightFooterLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 14)
        label.textAlignment = .right
        label.textColor = .white
        return label
    }()

    override func prepareForReuse() {
        super.prepareForReuse()

        logoImageView.kf.cancelDownloadTask()
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
        //  - Header:
        //      H|-[Name]-[Statue]-|
        //  - Content:
        //      H|-[Logo]-[Message]-|
        //                [Detail]
        //  - Footer:
        //      H|-[FooterLeft]-[FooterRight]-|
        cardView.layoutMargins = UIEdgeInsets(top: 10, left: 12, bottom: 12, right: 12)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: RedPacketCardTableViewCell.cardVerticalMargin),
            cardView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: RedPacketCardTableViewCell.cardVerticalMargin),
        ])
        
        headerContainerView.preservesSuperviewLayoutMargins = true
        headerContainerView.layoutMargins.bottom = 8
        headerContainerView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(headerContainerView)
        NSLayoutConstraint.activate([
            headerContainerView.topAnchor.constraint(equalTo: cardView.topAnchor),
            headerContainerView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            headerContainerView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
        ])
        
        headerVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        headerContainerView.addSubview(headerVisualEffectView)
        NSLayoutConstraint.activate([
            headerVisualEffectView.topAnchor.constraint(equalTo: headerContainerView.topAnchor),
            headerVisualEffectView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            headerVisualEffectView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            headerVisualEffectView.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
        ])
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerContainerView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: headerContainerView.layoutMarginsGuide.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: headerContainerView.layoutMarginsGuide.leadingAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: headerContainerView.layoutMarginsGuide.bottomAnchor),
        ])
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        headerContainerView.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 4),
            statusLabel.trailingAnchor.constraint(equalTo: headerContainerView.layoutMarginsGuide.trailingAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: nameLabel.bottomAnchor),
        ])
        statusLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(logoImageView)
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor, constant: 15),
            logoImageView.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor),
            logoImageView.heightAnchor.constraint(equalToConstant: 44),
            logoImageView.widthAnchor.constraint(equalToConstant: 44),
        ])

        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: logoImageView.topAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.trailingAnchor),
        ])
        
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(detailLabel)
        NSLayoutConstraint.activate([
            detailLabel.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 12),
            detailLabel.trailingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.trailingAnchor),
            detailLabel.bottomAnchor.constraint(equalTo: logoImageView.bottomAnchor),
        ])
        
//        redPacketStatusLabel.translatesAutoresizingMaskIntoConstraints = false
//        cardView.addSubview(redPacketStatusLabel)
//        NSLayoutConstraint.activate([
//            redPacketStatusLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
//            redPacketStatusLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor),
//            redPacketStatusLabel.trailingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.trailingAnchor),
//        ])
//        redPacketStatusLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
//
//        redPacketDetailLabel.translatesAutoresizingMaskIntoConstraints = false
//        cardView.addSubview(redPacketDetailLabel)
//        NSLayoutConstraint.activate([
//            redPacketDetailLabel.topAnchor.constraint(equalTo: redPacketStatusLabel.bottomAnchor, constant: 8),
//            redPacketDetailLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor),
//            redPacketDetailLabel.trailingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.trailingAnchor),
//        ])
//
        leftFooterLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(leftFooterLabel)
        NSLayoutConstraint.activate([
            leftFooterLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 11),
            leftFooterLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor),
            cardView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: leftFooterLabel.bottomAnchor),
        ])

        rightFooterLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(rightFooterLabel)
        NSLayoutConstraint.activate([
            rightFooterLabel.topAnchor.constraint(equalTo: leftFooterLabel.topAnchor),
            rightFooterLabel.leadingAnchor.constraint(equalTo: leftFooterLabel.trailingAnchor, constant: 8),
            rightFooterLabel.trailingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.trailingAnchor),
        ])
        rightFooterLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        nameLabel.text = "From: Sender"
        statusLabel.text = "Opening…"
        logoImageView.image = Asset.redPacketDefaultLogo.image
        messageLabel.text = "Best Wishes!"
        detailLabel.text = "0.2 ETH / 3 shares"
        leftFooterLabel.text = "2 hr ago created"
        rightFooterLabel.text = "2 hr ago received"

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
        .previewLayout(.fixed(width: 414, height: 136))
    }
}
#endif
