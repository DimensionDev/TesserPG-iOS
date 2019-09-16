//
//  SuggestionButton.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/3/4.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class SuggestionButton: UIButton, Thematic {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configUI()
    }
    
    private func configUI() {
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        setTitleColor(.black, for: .normal)
        setBackgroundImage(nil, for: .normal)
        
        setBackgroundImage(UIImage.placeholder(color: UIColor.clear), for: .normal)
        layer.masksToBounds = true
        layer.cornerRadius = 4
    }
    
    func updateColor(theme: Theme) {
        switch theme {
        case .light:
            setTitleColor(.black, for: .normal)
            setBackgroundImage(UIImage.placeholder(color: UIColor(hex: 0xF5F5F5)!), for: .highlighted)
            setBackgroundImage(UIImage.placeholder(color: UIColor(hex: 0xF5F5F5)!), for: .selected)
        case .dark:
            setTitleColor(.white, for: .normal)
            setBackgroundImage(UIImage.placeholder(color: ._systemGray), for: .highlighted)
            setBackgroundImage(UIImage.placeholder(color: ._systemGray), for: .selected)
        }
    }
}

