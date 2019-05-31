//
//  UIView+blinking.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/2/25.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

extension UIView {
    func addOpacityAnimation() {
        let key = "opacity"
        let animation = CABasicAnimation(keyPath: key)
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.duration = 0.5
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.autoreverses = true
        animation.repeatCount = Float.greatestFiniteMagnitude
        layer.add(animation, forKey: key)
    }
    
    public func addShadow(ofColor color: UIColor = UIColor(red: 0.07, green: 0.47, blue: 0.57, alpha: 1.0), radius: CGFloat = 3, offset: CGSize = .zero, opacity: Float = 0.5) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        layer.masksToBounds = false
    }
}
