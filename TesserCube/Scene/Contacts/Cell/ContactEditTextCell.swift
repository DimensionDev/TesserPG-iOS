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
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
}
