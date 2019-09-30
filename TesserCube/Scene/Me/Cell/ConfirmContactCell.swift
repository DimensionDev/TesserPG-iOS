//
//  ConfirmContactCell.swift
//  TesserCube
//
//  Created by jk234ert on 2019/7/2.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class ConfirmContactCell: UICollectionViewCell {
    
    @IBOutlet weak var cardView: TCCardView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    var userID: String? {
        didSet {
            updateModel()
        }
    }
    
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
        updateModel()
    }
    
    private func updateModel() {
        addressLabel.text = userID
        codeLabel.attributedText = NSAttributedString(string: keyValue.hashCodeString, attributes:
            [NSAttributedString.Key.font: FontFamily.SourceCodeProMedium.regular.font(size: 14) ?? Font.systemFont(ofSize: 14),
             NSAttributedString.Key.foregroundColor: UIColor.white,
             NSAttributedString.Key.paragraphStyle: paraghStyle
            ])
        statusLabel.text = keyValue.status
    }
}
