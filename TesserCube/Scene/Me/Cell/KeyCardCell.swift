//
//  KeyCardCell.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/18.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

enum KeyValue {
    case mockKey
    case TCKey(value: TCKey)
    
    var hashCodeString: String {
        switch self {
        case .mockKey:
            return "**** **** **** **** ****\n**** **** **** **** ****"
        case .TCKey(let key):
            return key.displayFingerprint ?? L10n.MeViewController.KeyCardCell.Label.invalidFingerprint
        }
    }
    
    var address: String {
        switch self {
        case .mockKey:
            return "****@*****.***"
        case .TCKey(let key):
            return key.userID
//            if let userID = key.keyRing.publicKeyRing.primaryKey.primaryUserID {
//                let meta = PGPUserIDTranslator(userID: userID)
//                return meta.name ?? meta.email ?? " " // userID should have one of name and email
//            }
//            
//            return L10n.Common.Label.nameNull
        }
    }
    
    var status: String {
        switch self {
        case .mockKey:
            return L10n.MeViewController.KeyCardCell.Label.noKeyYet
        case .TCKey(let key):
            let keySizeString = key.primaryKeyStrength?.string ?? L10n.Common.Label.nameUnknown
            let keySizeDescription = "\(keySizeString)-bit"
            
            let primaryKeyDescription: String? = {
                guard let algorithm = key.primaryKeyAlgorihm else {
                    return nil
                }

                // RSA or RSA3072
                return algorithm.displayName + (key.primaryKeyStrength.flatMap { String($0) } ?? "")
            }()

            // TODO: needs GoPGP subkey support
//            let primaryEncryptionKeyDescription: String? = {
//                guard key.hasSubkey else {
//                    return nil
//                }
//
//                if key.hasSubkey {
//                    let subkeySizeString = key.subkeyStrength?.string ?? L10n.Common.Label.nameUnknown
//                    let subkeyAlgorithmString = key.subkeyAlgorithm?.rawValue ?? L10n.Common.Label.nameUnknown
//                    let subkeyDescString = "\(subkeyAlgorithmString)\(subkeySizeString)"
//                    keyDescString.append(" + \(subkeyDescString)")
//                }
//                return ""
//            }()

            return [keySizeDescription, primaryKeyDescription].compactMap { $0 }.joined(separator: " / ")
        }
    }
}

class KeyCardCell: UITableViewCell {

    @IBOutlet weak var cardView: TCCardView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!

    static let cardVerticalMargin: CGFloat = 8.0
    
    var keyValue: KeyValue = .mockKey {
        didSet {
            updateModel()
        }
    }
    
    private let paraghStyle: NSParagraphStyle = {
        var style = NSMutableParagraphStyle()
        style.lineSpacing = 0
        style.maximumLineHeight = 14
        return style
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        updateModel()
    }
    
    private func updateModel() {
        addressLabel.text = keyValue.address
        codeLabel.attributedText = NSAttributedString(string: keyValue.hashCodeString, attributes:
            [
                NSAttributedString.Key.font: FontFamily.SourceCodeProMedium.regular.font(size: 14) ?? Font.systemFont(ofSize: 14.0),
                NSAttributedString.Key.foregroundColor: UIColor.white,
                NSAttributedString.Key.paragraphStyle: paraghStyle
            ]
        )
        statusLabel.text = keyValue.status
    }
}
