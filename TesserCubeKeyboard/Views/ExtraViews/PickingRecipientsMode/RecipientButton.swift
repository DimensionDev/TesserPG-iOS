//
//  RecipientButton.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/2/21.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class RecipientButton: UIButton, Thematic {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configUI()
    }
    
    private func configUI() {
        updateColor(theme: .light)
//        contentEdgeInsets = UIEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        
        layer.cornerRadius = 16
        layer.masksToBounds = true
        titleLabel?.font = UIFont.systemFont(ofSize: 18)
    }
    
    
    
    func updateColor(theme: Theme) {
        switch theme {
        case .light:
            setTitleColor(.white, for: .normal)
            setBackgroundImage(UIImage.placeholder(color: UIColor(hex: 0x1C8EFF)!), for: .normal)
        case .dark:
            break
        }
        
    }
}
