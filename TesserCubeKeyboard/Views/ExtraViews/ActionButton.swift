//
//  ActionButton.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/3/4.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class ActionButton: UIButton, Thematic {
    
    private let responseWidth: CGFloat = 60
    private let responseHeight: CGFloat = 42
    
    static let defaultWidth: CGFloat = 60
    static let defaultHeight: CGFloat = 42

    static let expandWidth: CGFloat = 158
    
    static let defaultSize = CGSize(width: ActionButton.defaultWidth, height: ActionButton.defaultHeight)
    static let expandSize = CGSize(width: ActionButton.expandWidth, height: ActionButton.defaultHeight)
    
    var action: ActionType = .modeChange {
        didSet {
            configUI()
        }
    }
    
    var isTitleVisible: Bool = false {
        didSet {
            configUI()
        }
    }
    
    private func configUI() {
        titleLabel?.font = FontFamily.SFProDisplay.regular.font(size: 16)
        titleEdgeInsets = UIEdgeInsets(top: 6, left: 0, bottom: 0, right: 0)
        setTitleColor(.black, for: .normal)
        setTitleColor(.lightGray, for: .disabled)
        if isTitleVisible {
            imageEdgeInsets = UIEdgeInsets(top: 6, left: -8, bottom: 0, right: 0)
            setTitle(action.title, for: .normal)
            adjustsImageWhenHighlighted = true
        } else {
            imageEdgeInsets = UIEdgeInsets(top: 6, left: 0, bottom: 0, right: 0)
            adjustsImageWhenHighlighted = false
            setTitle(nil, for: .normal)
        }
        setBackgroundImage(UIImage.placeholder(color: UIColor.clear), for: .normal)
        updateColor(theme: KeyboardModeManager.shared.currentTheme)
    }
    
    func updateColor(theme: Theme) {
        setImage(action.highlightImage(theme: theme), for: .highlighted)
        setImage(action.selectedImage(theme: theme), for: .selected)
        setImage(action.image(theme: theme), for: .normal)
        setImage(action.disabledImage(theme: theme), for: .disabled)
        
        switch theme {
        case .light:
            setTitleColor(.black, for: .normal)
            setTitleColor(.lightGray, for: .disabled)
        case .dark:
            setTitleColor(.white, for: .normal)
            setTitleColor(.lightGray, for: .disabled)
        }
    }
}
