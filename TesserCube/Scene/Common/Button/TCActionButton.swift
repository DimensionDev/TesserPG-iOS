//
//  TCActionButton.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/18.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

@IBDesignable
class TCActionButton: UIButton {
    
    private var shadow2Layer: CALayer?
    
    var minHeight: CGFloat = 50
    
    private let insetLength: CGFloat = 7.5
    
    private let lightGlowLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.white.withAlphaComponent(0.07).cgColor, UIColor.white.withAlphaComponent(0).cgColor]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 0.5)
        layer.masksToBounds = true
        layer.cornerRadius = 10
        return layer
    }()
    
    private let shadowGlowLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.black.withAlphaComponent(0).cgColor, UIColor.black.withAlphaComponent(0.01).cgColor]
        layer.startPoint = CGPoint(x: 0.5, y: 0.86)
        layer.endPoint = CGPoint(x: 0.5, y: 1.0)
        layer.masksToBounds = true
        layer.cornerRadius = 10
        return layer
    }()
    
    @IBInspectable
    public var buttonCornerRadius: CGFloat = 8 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    public var color: UIColor = .white {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    public var highlightedColor: UIColor = .white {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    public var selectedColor: UIColor = .white {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    public var disabledColor: UIColor = .white {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configUI()
    }
    
    private func configUI() {
//        adjustsImageWhenDisabled = false
//        adjustsImageWhenHighlighted = false
        
        cornerRadius = buttonCornerRadius
        shadow2Layer = CALayer(layer: layer)
        layer.insertSublayer(shadow2Layer!, at: 0)
        
        layer.addSublayer(lightGlowLayer)
        layer.addSublayer(shadowGlowLayer)
        titleLabel?.font = FontFamily.SFProDisplay.medium.font(size: 17)
    }
    
    override open func draw(_ rect: CGRect) {
        updateBackgroundImages()
        super.draw(rect)
    }
    
    override var intrinsicContentSize: CGSize {
        let originSize = super.intrinsicContentSize
        return CGSize(width: originSize.width, height: max(originSize.height, minHeight))
    }
    
    fileprivate func updateBackgroundImages() {
        
        let normalImage = ImageUtil.buttonImage(color: color, shadowHeight: 0, shadowColor: .clear, cornerRadius: buttonCornerRadius)
        let highlightedImage = ImageUtil.buttonImage(color: highlightedColor, shadowHeight: 0, shadowColor: .clear, cornerRadius: buttonCornerRadius)
        let selectedImage = ImageUtil.buttonImage(color: selectedColor, shadowHeight: 0, shadowColor: .clear, cornerRadius: buttonCornerRadius)
        let disabledImage = ImageUtil.buttonImage(color: disabledColor, shadowHeight: 0, shadowColor: .clear, cornerRadius: buttonCornerRadius)
        
        setBackgroundImage(normalImage, for: .normal)
//        setBackgroundImage(highlightedImage, for: .highlighted)
//        setBackgroundImage(selectedImage, for: .selected)
//        setBackgroundImage(disabledImage, for: .disabled)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shadow2Layer?.frame = bounds
        lightGlowLayer.frame = bounds
        shadowGlowLayer.frame = bounds
        
        layer.addSketchShadow(color: .black, alpha: 0.02, x: 0, y: 1, blur: 3, spread: 1, roundedRect: bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: buttonCornerRadius, height: buttonCornerRadius))
//
        shadow2Layer?.addSketchShadow(color: .black, alpha: 0.02, x: 0, y: 1, blur: 8, spread: 0, roundedRect: bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: buttonCornerRadius, height: buttonCornerRadius))
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var hittestInset = UIEdgeInsets(top: 0, left: -insetLength, bottom: 0, right: -insetLength)
        let hitTestFrame = bounds.inset(by: hittestInset)
        return hitTestFrame.contains(point)
    }
}
