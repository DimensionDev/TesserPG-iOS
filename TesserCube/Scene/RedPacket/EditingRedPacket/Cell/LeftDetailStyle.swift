//
//  LeftDetailStyle.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-22.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

protocol LeftDetailStyle: class {
    var titleLabel: UILabel { get }
    var detailLeadingLayoutConstraint: NSLayoutConstraint! { get }
}
