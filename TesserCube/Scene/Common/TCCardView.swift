//
//  TCCardView.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/18.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit

@IBDesignable
class TCCardView: UIView {
    
    @IBInspectable
    var cardBackgroundColor: UIColor? {
        set {
            backgroundView.backgroundColor = newValue
        }
        get {
            return backgroundView.backgroundColor
        }
    }
    
    @IBInspectable
    var cardCornerRadius: CGFloat = 10
    
    private let backgroundView = UIView(frame: .zero)
    private let glowLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.white.withAlphaComponent(0.06).cgColor, UIColor.white.withAlphaComponent(0)]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 0.5)
        return layer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configUI()
    }
    
    func configUI() {
        backgroundColor = .clear
        insertSubview(backgroundView, at: 0)
        backgroundView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        
        backgroundView.layer.masksToBounds = true
        backgroundView.layer.cornerRadius = cardCornerRadius
        
        backgroundView.layer.addSublayer(glowLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.addSketchShadow(color: .black, alpha: 0.11, x: 0, y: 5, blur: 17, spread: 0, roundedRect: bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: cardCornerRadius, height: cardCornerRadius))
        glowLayer.frame = backgroundView.bounds
    }

    override func action(for layer: CALayer, forKey event: String) -> CAAction? {
        guard event == "shadowPath" else {
            return super.action(for: layer, forKey: event)
        }

        guard let priorPath = layer.shadowPath else {
            return super.action(for: layer, forKey: event)
        }

        guard let sizeAnimation = layer.animation(forKey: "bounds.size") as? CABasicAnimation else {
            return super.action(for: layer, forKey: event)
        }

        // swiftlint:disable force_cast
        let animation = sizeAnimation.copy() as! CABasicAnimation
        // swiftlint:enable force_cast
        animation.keyPath = "shadowPath"
        let action = ShadowingViewAction()
        action.priorPath = priorPath
        action.pendingAnimation = animation
        return action
    }

}

// fix shadow render to target frame before animation finish issue
// Ref: https://stackoverflow.com/a/47472010/3797903
private class ShadowingViewAction: NSObject, CAAction {
    var pendingAnimation: CABasicAnimation?
    var priorPath: CGPath?

    func run(forKey event: String, object anObject: Any, arguments dict: [AnyHashable: Any]?) {
        guard let layer = anObject as? CALayer, let animation = self.pendingAnimation else {
            return
        }

        animation.fromValue = self.priorPath
        animation.toValue = layer.shadowPath
        layer.add(animation, forKey: "shadowPath")
    }
}
