//
//  SettingsTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-5-15.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift

class SettingsTableViewCell: UITableViewCell {

    var disposeBag = DisposeBag()

    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
    }

}
