//
//  ToastAlerter.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/3/29.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit

class ToastAlerter {
    func alert(message: String, in view: UIView, duration: Double = 4) {
        DispatchQueue.main.async {
            let label = self.createLabel(message: message)
            let container = self.createContainerView(label: label, in: view)
            UIView.animate(withDuration: duration, animations: {
                container.alpha = 0
            }, completion: { _ in
                container.removeFromSuperview()
            })
        }
    }
}

fileprivate extension ToastAlerter {
    func createLabel(message: String) -> UILabel {
        let label = UILabel(frame: .zero)
        label.text = message
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = FontFamily.SFProDisplay.regular.font(size: 16)
        label.textColor = .white
        label.lineBreakMode = .byWordWrapping
        return label
    }
    
    func createContainerView(label: UILabel, in view: UIView) -> UIView {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.layer.masksToBounds = true
        blurEffectView.layer.cornerRadius = 4
        blurEffectView.backgroundColor = UIColor(hex: 0x111111, transparency: 0.5)
        
//        let container = UIView(frame: .zero)
//        container.backgroundColor = .black
//        let effectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: .init(style: .dark)))
//        container.addSubview(effectView)
//        effectView.contentView.addSubview(label)
//        container.addSubview(label)
        
        blurEffectView.contentView.addSubview(label)
        
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.center.equalToSuperview()
        }
        
//        effectView.snp.makeConstraints { maker in
//            maker.edges.equalToSuperview()
//        }
        
        view.addSubview(blurEffectView)
        
        blurEffectView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.leading.equalToSuperview().offset(13)
            maker.trailing.equalToSuperview().offset(-13)
            maker.height.equalTo(60)
        }
        view.layoutSubviews()

        blurEffectView.isUserInteractionEnabled = false
        return blurEffectView
    }
}
