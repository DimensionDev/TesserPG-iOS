//
//  UIScreen.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-4-10.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

extension UIScreen {

    var center: CGPoint {
        return CGPoint(x: UIScreen.main.bounds.width * 0.5, y: UIScreen.main.bounds.height * 0.5)
    }
    
}
