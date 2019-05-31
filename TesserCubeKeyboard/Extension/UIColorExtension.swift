//
//  UIColorExtension.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/2/21.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

extension UIColor {
    /// SwifterSwift: Create Color from RGB values with optional transparency.
    ///
    /// - Parameters:
    ///   - red: red component.
    ///   - green: green component.
    ///   - blue: blue component.
    ///   - transparency: optional transparency value (default is 1).
    public convenience init?(red: Int, green: Int, blue: Int, transparency: CGFloat = 1) {
        guard red >= 0 && red <= 255 else { return nil }
        guard green >= 0 && green <= 255 else { return nil }
        guard blue >= 0 && blue <= 255 else { return nil }
        
        var trans = transparency
        if trans < 0 { trans = 0 }
        if trans > 1 { trans = 1 }
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: trans)
    }
    
    /// SwifterSwift: Create Color from hexadecimal value with optional transparency.
    ///
    /// - Parameters:
    ///   - hex: hex Int (example: 0xDECEB5).
    ///   - transparency: optional transparency value (default is 1).
    public convenience init?(hex: Int, transparency: CGFloat = 1) {
        var trans = transparency
        if trans < 0 { trans = 0 }
        if trans > 1 { trans = 1 }
        
        let red = (hex >> 16) & 0xff
        let green = (hex >> 8) & 0xff
        let blue = hex & 0xff
        self.init(red: red, green: green, blue: blue, transparency: trans)
    }
    
}
