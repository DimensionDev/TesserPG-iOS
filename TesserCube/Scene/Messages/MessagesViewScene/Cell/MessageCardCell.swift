//
//  MessageCardCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-3-25.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit

protocol MessageCardCellDelegate: class {
    func messageCardCell(_ cell: MessageCardCell, expandButtonPressed: UIButton)
}

final class MessageCardCell: UITableViewCell {

    static let cardVerticalMargin: CGFloat = 8

    weak var delegate: MessageCardCellDelegate?

    let cardView: TCCardView = {
        let cardView = TCCardView()
        return cardView
    }()
    let headerBackgroundView: UIView = {
        let view = UIView()
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return view
    }()
    let signedByLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProDisplay.regular.font(size: 14)
        label.text = L10n.MessageCardCell.Label.signedBy
        return label
    }()
    let signedByStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    let recipeintsLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProDisplay.regular.font(size: 14)
        label.text = L10n.MessageCardCell.Label.recipeints
        return label
    }()
    let recipeintsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 4
        label.text = String(repeating: "Message content here. ", count: 10)
        label.contentMode = .top
        return label
    }()
    let leftFooterLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProDisplay.regular.font(size: 14)
        label.text = "Left Footer"
        return label
    }()
    let rightFooterLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProDisplay.regular.font(size: 14)
        label.text = "Right Footer"
        label.textAlignment = .right
        return label
    }()

    lazy var extraBackgroundViewHeightConstraint = extraBackgroundView.heightAnchor.constraint(equalToConstant: 0)
    lazy var extraBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = cardView.cardCornerRadius
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        view.clipsToBounds = true
        return view
    }()

    lazy var expandButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = FontFamily.SFProText.regular.font(size: 17)
        button.titleLabel?.textAlignment = .center
        button.setTitle("Expand Button", for: .normal)
        button.addTarget(self, action: #selector(MessageCardCell.expandButtonPressed(_:)), for: .touchUpInside)
        return button
    }()

    override func prepareForReuse() {
        super.prepareForReuse()

        signedByStackView.subviews.forEach { $0.removeFromSuperview() }
        recipeintsStackView.subviews.forEach { $0.removeFromSuperview() }

        leftFooterLabel.text = ""
        rightFooterLabel.text = ""
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _init()
    }

    func _init() {
        clipsToBounds = false
        contentView.clipsToBounds = false
        setupUI()
        setupColor()
    }

}

extension MessageCardCell {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupColor()
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        // only enable selection background when isEditing
        selectionStyle = editing ? .default : .none
        expandButton.isEnabled = !editing
    }

}

extension MessageCardCell {

    func setupUI() {
        // - Card
        //  [StackView]
        //   - Header
        //     - Signed By: [name, email, shortID]
        //     - Recipeints: [name, email, shortID]
        //   - Content:
        //      - Message: (Message Content)
        //      - Footer: (left, right)
        //   - Extra: Expand Button (default hidden)

        // Card
        cardView.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(MessageCardCell.cardVerticalMargin)
            maker.bottom.equalToSuperview().offset(-MessageCardCell.cardVerticalMargin)
            maker.leading.trailing.equalTo(contentView.layoutMarginsGuide)
        }

        // [StackView]
        let stackView = UIStackView(frame: .zero)
        stackView.axis = .vertical
        stackView.distribution = .fill
        cardView.addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.top.leading.trailing.bottom.equalToSuperview()
        }

        // Header
        headerBackgroundView.layer.cornerRadius = cardView.cardCornerRadius
        headerBackgroundView.addSubview(signedByLabel)
        signedByLabel.snp.makeConstraints { maker in
            maker.top.equalTo(headerBackgroundView.snp.topMargin)
            maker.leading.equalTo(headerBackgroundView.snp.leadingMargin)
        }
        signedByLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        signedByLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        signedByLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        headerBackgroundView.addSubview(signedByStackView)
        signedByStackView.snp.makeConstraints { maker in
            maker.top.equalTo(signedByLabel.snp.top)
            maker.leading.equalTo(signedByLabel.snp.trailing).offset(4)
            maker.trailing.equalTo(headerBackgroundView.snp.trailingMargin)
            maker.height.greaterThanOrEqualTo(signedByLabel.snp.height)
        }

        headerBackgroundView.addSubview(recipeintsLabel)
        recipeintsLabel.snp.makeConstraints { maker in
            maker.top.equalTo(signedByStackView.snp.bottom).offset(4)
            maker.leading.equalTo(headerBackgroundView.snp.leadingMargin)
            maker.width.equalTo(signedByLabel.snp.width)
        }
        recipeintsLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        recipeintsLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        recipeintsLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        recipeintsLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        headerBackgroundView.addSubview(recipeintsStackView)
        recipeintsStackView.snp.makeConstraints { maker in
            maker.top.equalTo(recipeintsLabel.snp.top)
            maker.leading.equalTo(signedByStackView.snp.leading)
            maker.trailing.equalTo(headerBackgroundView.snp.trailingMargin)
            maker.height.greaterThanOrEqualTo(recipeintsLabel.snp.height)
            maker.bottom.equalTo(headerBackgroundView.snp.bottomMargin)
        }

        // Content
        let contentBackgroundView: UIView = {
            let view = UIView()
            view.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
            return view
        }()

        // Message
        contentBackgroundView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { maker in
            maker.top.equalTo(contentBackgroundView.snp.topMargin)
            maker.leading.equalTo(contentBackgroundView.layoutMarginsGuide)
            maker.trailing.lessThanOrEqualTo(contentBackgroundView.snp.trailingMargin)
        }
        messageLabel.setContentHuggingPriority(.init(100), for: .vertical)
        messageLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        // fix message label strange moveing animation when tableView set isEditing to true
        let indentAnimationFixPaddingView = UIView()
        contentBackgroundView.addSubview(indentAnimationFixPaddingView)
        indentAnimationFixPaddingView.snp.makeConstraints { maker in
            maker.leading.equalTo(messageLabel)
            maker.trailing.equalToSuperview()
            maker.centerY.equalTo(messageLabel.snp.centerY)
            maker.height.equalTo(CGFloat.leastNonzeroMagnitude)
            maker.width.equalTo(CGFloat.leastNonzeroMagnitude)
        }
        indentAnimationFixPaddingView.setContentHuggingPriority(.required, for: .horizontal)
        indentAnimationFixPaddingView.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Footer
        contentBackgroundView.addSubview(leftFooterLabel)
        leftFooterLabel.snp.makeConstraints { maker in
            maker.top.equalTo(messageLabel.snp.bottom).offset(16)
            maker.leading.equalTo(contentBackgroundView.snp.leadingMargin)
            maker.bottom.equalTo(contentBackgroundView.snp.bottomMargin)
        }
        leftFooterLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        leftFooterLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        contentBackgroundView.addSubview(rightFooterLabel)
        rightFooterLabel.snp.makeConstraints { maker in
            maker.top.equalTo(leftFooterLabel.snp.top)
            maker.leading.equalTo(leftFooterLabel.snp.trailing).offset(8)
            maker.trailing.equalTo(contentBackgroundView.snp.trailingMargin)
        }
        rightFooterLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rightFooterLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        // Extra
        extraBackgroundView.snp.makeConstraints { maker in
            maker.height.equalTo(44)
        }

        extraBackgroundView.addSubview(expandButton)
        expandButton.snp.makeConstraints { maker in
            maker.top.equalTo(extraBackgroundView.snp.top)
            maker.leading.equalTo(extraBackgroundView.snp.leading)
            maker.trailing.equalTo(extraBackgroundView.snp.trailing)
            maker.bottom.equalTo(extraBackgroundView.snp.bottom)
        }

        extraBackgroundViewHeightConstraint.isActive = true
        [headerBackgroundView, contentBackgroundView, extraBackgroundView].forEach { view in
            stackView.addArrangedSubview(view)
        }
    }

    func setupColor() {
        // Set background color to clear to prevent shadow clipped
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.cardBackgroundColor = .cardBackground
        headerBackgroundView.backgroundColor = .cardHeaderBackground

        signedByLabel.textColor = ._secondaryLabel
        recipeintsLabel.textColor = ._secondaryLabel

        leftFooterLabel.textColor = ._tertiaryLabel
        rightFooterLabel.textColor = ._tertiaryLabel

        extraBackgroundView.backgroundColor = .cardExtraBackground
    }

}

extension MessageCardCell {

    @objc func expandButtonPressed(_ sender: UIButton) {
        delegate?.messageCardCell(self, expandButtonPressed: sender)
    }

}

fileprivate extension UIColor {

    static let cardBackground: UIColor = {
        // use white in light mode
        let color: UIColor = .white

        if #available(iOS 13.0, *) {
            return UIColor { trait -> UIColor in
                switch trait.userInterfaceStyle {
                case .dark:     return UIColor(white: 1.0, alpha: 0.05)
                default:        return color
                }
            }
        } else {
            return color
        }
    }()

    static let cardHeaderBackground: UIColor = {
        // use systemGray6 in light mode
        let _systemGray6 = UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 247.0/255.0, alpha: 1.0)

        if #available(iOS 13, *) {
            return UIColor { trait -> UIColor in
                switch trait.userInterfaceStyle {
                case .dark:     return .tertiarySystemBackground    // use 3rd background color in dark mode
                default:        return _systemGray6
                }
            }
        } else {
            return _systemGray6
        }
    }()

    static let cardExtraBackground: UIColor = {
        let _systemGray6 = UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 247.0/255.0, alpha: 1.0)

        if #available(iOS 13, *) {
            return UIColor { trait -> UIColor in
                switch trait.userInterfaceStyle {
                case .dark:     return .tertiarySystemBackground
                default:        return _systemGray6
                }
            }
        } else {
            return _systemGray6
        }
    }()

}

final class MessageContactInfoView: UIView {
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.semibold.font(size: 14)
        return label
    }()
    
    let emailLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 14)
        label.textColor = ._secondaryLabel
        return label
    }()
    
    let shortIDLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SourceCodeProMedium.regular.font(size: 14)
        label.textColor = .systemGreen
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
        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        addSubview(emailLabel)
        emailLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(nameLabel.snp.trailing).offset(2)
            maker.top.bottom.equalToSuperview()
        }
        emailLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        emailLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        addSubview(shortIDLabel)
        shortIDLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(emailLabel.snp.trailing)
            maker.top.trailing.bottom.equalToSuperview()
        }
        shortIDLabel.setContentHuggingPriority(.required, for: .horizontal)
        shortIDLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
}
