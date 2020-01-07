//
//  InterpretResultView.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/4/7.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit
import DateToolsSwift

protocol InterpretResultViewViewDelegate: class {
    func interpretResultViewView(_ view: InterpretResultView, didClickedClose button: UIButton)
}

class InterpretResultView: UIView, Thematic {
    
    enum ResultType {
        case success
        case badSignature
        case unknownSender
        
        func titleColor(theme: Theme) -> UIColor {
            switch self {
            case .success:
                return theme == .light ? .black : .black
            case .badSignature:
                return theme == .light ? .white : .white
            case .unknownSender:
                return theme == .light ? .black : .black
            }
        }
        
        func backgroundColor(theme: Theme) -> UIColor {
            switch self {
            case .success:
                return theme == .light ? UIColor(hex: 0x7CE667)! : UIColor(hex: 0x7CE667)!
            case .badSignature:
                return theme == .light ? UIColor(hex: 0xF20000)! : UIColor(hex: 0xF20000)!
            case .unknownSender:
                return theme == .light ? UIColor(hex: 0xFFE500)! : UIColor(hex: 0xFFE500)!
            }
        }
        
        func closeButtonImage(theme: Theme) -> UIImage {
            switch self {
            case .success:
                return theme == .light ? Asset.buttonInterpretedCloseBlack.image : Asset.buttonInterpretedCloseBlack.image
            case .badSignature:
                return theme == .light ? Asset.buttonInterpretedCloseWhite.image : Asset.buttonInterpretedCloseWhite.image
            case .unknownSender:
                return theme == .light ? Asset.buttonInterpretedCloseBlack.image : Asset.buttonInterpretedCloseBlack.image
            }
        }
        
        var title: String {
            switch self {
            case .success:
                return L10n.Keyboard.Interpreted.Title.messageInterpreted
            case .badSignature:
                return L10n.Keyboard.Interpreted.Title.badSignature
            case .unknownSender:
                return L10n.Keyboard.Interpreted.Title.unknownSender
            }
        }
    }
    
    var resultType: ResultType?
    var theme: Theme = .light
    
    var message: Message? {
        didSet {
            updateUI()
        }
    }
    
    weak var delegate: InterpretResultViewViewDelegate?
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = FontFamily.SFProDisplay.medium.font(size: 16)
        label.text = L10n.Keyboard.Interpreted.Title.noNeccessaryPrivateKey
        return label
    }()
    
    let cardView: TCCardView = {
        let cardView = TCCardView()
        cardView.cardBackgroundColor = .white
        return cardView
    }()
    
    let signedByLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProDisplay.regular.font(size: 14)
        label.textColor = ._systemGray
        label.text = L10n.MessageCardCell.Label.signedBy
        return label
    }()
    
    let signedUserNameLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProDisplay.bold.font(size: 14)
        label.textColor = .black
        return label
    }()
    
    let signedUserEmailLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProDisplay.regular.font(size: 14)
        label.textColor = ._systemGray
        return label
    }()
    
    let signedUserIdentifierLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SourceCodeProMedium.regular.font(size: 12)
        label.textColor = .systemGreen
        return label
    }()
    
    let recipeintsLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProDisplay.regular.font(size: 14)
        label.textColor = ._systemGray
        label.text = L10n.MessageCardCell.Label.recipeints
        return label
    }()
    
    let recipientsNameLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProDisplay.bold.font(size: 14)
        label.textColor = .black
        return label
    }()
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.text = String(repeating: "Message content here. ", count: 10)
        label.font = FontFamily.SFProDisplay.regular.font(size: 16)
        label.textColor = .black
        return label
    }()
    
    let leftFooterLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProDisplay.regular.font(size: 14)
        label.textColor = ._systemGray
//        label.text = "Left Footer"
        return label
    }()
    let rightFooterLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProDisplay.regular.font(size: 14)
        label.textColor = ._systemGray
//        label.text = "Right Footer"
        label.textAlignment = .right
        return label
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(frame: .zero)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configUI()
    }
    
    private func configUI() {
        
        addSubview(titleLabel)
        addSubview(closeButton)
        
        closeButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(7)
            maker.trailing.equalToSuperview().offset(-7)
            maker.size.equalTo(CGSize(width: 28, height: 28))
        }
        
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(11)
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalTo(closeButton.snp.leading).offset(-16)
        }
        
        closeButton.addTarget(self, action: #selector(closeButtonDidClicked(_:)), for: .touchUpInside)
        
        addSubview(cardView)
        cardView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalTo(titleLabel.snp.bottom).offset(11)
            maker.bottom.equalToSuperview().offset(-6)
        }
        
        cardView.addSubview(signedByLabel)
        cardView.addSubview(signedUserNameLabel)
        cardView.addSubview(signedUserEmailLabel)
        cardView.addSubview(signedUserIdentifierLabel)
        cardView.addSubview(recipeintsLabel)
        cardView.addSubview(recipientsNameLabel)
        cardView.addSubview(messageLabel)
        cardView.addSubview(leftFooterLabel)
        cardView.addSubview(rightFooterLabel)
        
        signedByLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(12)
            maker.top.equalToSuperview().offset(12)
        }
        
        recipeintsLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(signedByLabel.snp.leading)
            maker.top.equalTo(signedByLabel.snp.bottom)
        }
        
        signedUserNameLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(recipeintsLabel.snp.trailing).offset(6)
            maker.top.equalTo(signedByLabel.snp.top)
        }
        
        signedUserEmailLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(signedUserNameLabel.snp.trailing).offset(2)
            maker.lastBaseline.equalTo(signedUserNameLabel.snp.lastBaseline)
            maker.trailing.equalTo(signedUserIdentifierLabel.snp.leading).offset(-6)
        }
        
        signedUserIdentifierLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(12)
            maker.trailing.equalToSuperview().offset(-12)
        }
        
        recipientsNameLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(signedUserNameLabel.snp.leading)
            maker.lastBaseline.equalTo(recipeintsLabel.snp.lastBaseline)
            maker.trailing.equalToSuperview().offset(-12)
        }
        
        messageLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(signedByLabel.snp.leading)
            maker.top.equalTo(recipeintsLabel.snp.bottom).offset(24)
            maker.trailing.equalToSuperview().offset(-12)
        }
        
        leftFooterLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(signedByLabel.snp.leading)
            maker.bottom.equalToSuperview().offset(-12)
//            maker.top.equalTo(messageLabel.snp.bottom).offset(16)
        }
        
        rightFooterLabel.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalTo(messageLabel.snp.bottom).offset(16)
        }
        
        signedByLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        signedByLabel.setContentHuggingPriority(.required, for: .horizontal)
        recipeintsLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        recipeintsLabel.setContentHuggingPriority(.required, for: .horizontal)

        signedUserIdentifierLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        signedUserIdentifierLabel.setContentHuggingPriority(.required, for: .horizontal)
    }
    
    private func updateUI() {
        guard let messageModel = message else { return }
        resultType = .success
        backgroundColor = resultType?.backgroundColor(theme: theme)
        titleLabel.textColor = resultType?.titleColor(theme: theme)
        titleLabel.text = resultType?.title
        closeButton.setImage(resultType?.closeButtonImage(theme: theme), for: .normal)
        
        messageLabel.text = message?.rawMessage
        let senderMeta = DMSPGPUserIDTranslator(userID: messageModel.senderKeyUserId)
        signedUserNameLabel.text = senderMeta.name
        signedUserEmailLabel.text = senderMeta.email.flatMap { "(\($0))"}
        signedUserIdentifierLabel.text = String(messageModel.senderKeyId.suffix(8))
        
        let recipeintsInfoList = messageModel.getRecipients().compactMap { recipient -> String? in
            let meta = DMSPGPUserIDTranslator(userID: recipient.keyUserId)
            return meta.name
        }
        let recipietnsListString = recipeintsInfoList.joined(separator: ",")
        recipientsNameLabel.text = recipietnsListString
        
        leftFooterLabel.text = messageModel.interpretedAt?.timeAgoSinceNow
    }
    
    @objc
    private func closeButtonDidClicked(_ sender: UIButton) {
        delegate?.interpretResultViewView(self, didClickedClose: sender)
    }
    
    func updateColor(theme: Theme) {
        
    }
}
