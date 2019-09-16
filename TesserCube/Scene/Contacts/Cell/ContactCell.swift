//
//  ContactCell.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/27.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class ContactCell: UITableViewCell {
    
    @IBOutlet weak var contactNameLabel: UILabel!
    
    var contact: Contact? {
        didSet {
            updateModel()

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
    
    private func updateModel() {
        contactNameLabel.text = contact?.name
        
        let hasSecretKey = contact?.getKeys().reduce(false, { (hasSecretKey, key) -> Bool in
            return hasSecretKey || key.hasSecretKey
        }) ?? false


        if #available(iOS 13.0, *) {
            switch traitCollection.userInterfaceStyle {
            case .dark:
                contactNameLabel.font = hasSecretKey ? FontFamily.SFProText.semibold.font(size: 17) : FontFamily.SFProText.light.font(size: 17)
            default:
                contactNameLabel.font = hasSecretKey ? FontFamily.SFProText.semibold.font(size: 17) : FontFamily.SFProText.regular.font(size: 17)
            }
        } else {
            contactNameLabel.font = hasSecretKey ? FontFamily.SFProText.semibold.font(size: 17) : FontFamily.SFProText.regular.font(size: 17)
        }
    }

}

extension ContactCell {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateModel()
    }

}
