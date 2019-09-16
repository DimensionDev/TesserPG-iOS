//
//  ContactEditTextCell.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/28.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class ContactEditTextCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var inputTextField: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        contentView.backgroundColor = .cellBackground
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
}


fileprivate extension UIColor {

    static let cellBackground: UIColor = {
        let color = UIColor.white

        if #available(iOS 13, *) {
            return UIColor { trait -> UIColor in
                switch trait.userInterfaceStyle {
                case .dark:     return .secondarySystemBackground
                default:        return color
                }
            }
        } else {
            return color
        }
    }()

}
