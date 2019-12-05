//
//  RecipientCellTableViewCell.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/3/6.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class RecipientCellTableViewCell: UITableViewCell {
    
    static let identifier = "RecipientCellTableViewCell"
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var serialLabel: UILabel!
    
    var contactInfo: FullContactInfo? {
        didSet {
            configUI()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func configUI() {
//        usernameLabel.text = account?.username
//        addressLabel.text = account?.address
//        serialLabel.text = account?.serial
        
        usernameLabel.text = contactInfo?.contact.name
        addressLabel.text = contactInfo?.emails.first?.address
        serialLabel.text = contactInfo?.keys.first?.shortIdentifier
        
        #if TARGET_IS_EXTENSION
        updateColor(theme: KeyboardModeManager.shared.currentTheme)
        #endif
    }

    // TODO: color
    private func updateColor(theme: Theme) {
        let backgroundColor: UIColor = theme == .light ? .white : .keyboardBackgroundDark
        let shadowColor: UIColor = theme == .light ? UIColor(hex: 0xDDDDDD)! : .keyboardFuncKeyBackgroundDark
        
        let usernameLabelColor = (theme == .light ? UIColor.black : UIColor.white)
        let addressLabelColor = (theme == .light ? UIColor(hex: 0x999999)! : UIColor.white.withAlphaComponent(0.5))
        
        contentView.backgroundColor = backgroundColor
        contentView.addShadow(ofColor: shadowColor, radius: 0, offset: CGSize(width: 0, height: 1))
        
        usernameLabel.textColor = usernameLabelColor
        addressLabel.textColor = addressLabelColor
    }
}
