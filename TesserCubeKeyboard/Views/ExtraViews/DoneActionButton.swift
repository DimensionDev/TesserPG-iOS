//
//  DoneActionButton.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/2/21.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class DoneActionButton: UIButton, Thematic {
    
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
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16)
        titleLabel?.font = UIFont.systemFont(ofSize: 18)
    }
    
    
    
    func updateColor(theme: Theme) {
        switch theme {
        case .light:
            setTitleColor(.black, for: .normal)
            setTitleColor(.gray, for: .disabled)
        case .dark:
            break
        }
        
    }
}
