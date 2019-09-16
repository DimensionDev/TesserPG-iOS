//
//  UIColor+Keyboard.swift
//  TesserCubeKeyboard
//
//  Created by Cirno MainasuK on 2019-9-16.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

extension UIColor {

    static let keyboardBackgroundLight: UIColor = {
       // #0xD1D3D9
       return UIColor(red: 209.0/255.0, green: 211.0/255.0, blue: 217.0/255.0, alpha: 1.0)
   }()

    static let keyboardBackgroundDark: UIColor = {
        // ##3C3D3E
        return UIColor(red: 60.0/255.0, green: 61.0/255.0, blue: 62.0/255.0, alpha: 1.0)
    }()

    static let keyboardCharKeyBackgroundDark: UIColor = {
        // #434343
        return UIColor(red: 67.0/255.0, green: 67.0/255.0, blue: 67.0/255.0, alpha: 1.0)
    }()

    static let keyboardFuncKeyBackgroundDark: UIColor = {
        // #242424
        return UIColor(red: 36.0/255.0, green: 36.0/255.0, blue: 36.0/255.0, alpha: 1.0)
    }()

}
