//
//  ModeSwitchView.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 12/19/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

protocol ModeSwitchViewDelegate: class {
    func modeSwitchView(_ modeSwitchView: ModeSwitchView, modeSwitchButtonDidClicked action: TCKeyboardMode)
}

extension TCKeyboardMode {
    func image(theme: Theme) -> UIImage {
        switch theme {
        case .light:
            switch self {
            case .encrypt:
                return #imageLiteral(resourceName: "button_lock_normal")
            case .redpacket:
                return #imageLiteral(resourceName: "button_interpret_normal")
            case .sign:
                return #imageLiteral(resourceName: "button_modeChange_icon")
            }
        case .dark:
            switch self {
            case .encrypt:
                return #imageLiteral(resourceName: "button_lock_normal_dark")
            case .redpacket:
                return #imageLiteral(resourceName: "button_interpret_normal_dark")
            case .sign:
                return #imageLiteral(resourceName: "button_modeChange_icon_dark")
            }
        }
    }
    
    var title: String? {
        switch self {
        case .encrypt:
            return L10n.Keyboard.Button.encrypt
        case .redpacket:
            return "Red Packet" //TODO: i18n
        case .sign:
            return "Sign"
        }
    }
}

class ModeSwitchActionButton: UIButton, Thematic {
    
    var action: TCKeyboardMode = .encrypt {
        didSet {
            configUI()
        }
    }
    
    var isTitleVisible: Bool = true {
        didSet {
            configUI()
        }
    }
    
    private func configUI() {
        titleLabel?.font = FontFamily.SFProDisplay.regular.font(size: 16)
//        titleEdgeInsets = UIEdgeInsets(top: 6, left: 0, bottom: 0, right: 0)
        setTitleColor(.black, for: .normal)
        setTitleColor(.lightGray, for: .disabled)
        if isTitleVisible {
//            imageEdgeInsets = UIEdgeInsets(top: 0, left: -16, bottom: 0, right: 0)
            setTitle(action.title, for: .normal)
//            adjustsImageWhenHighlighted = true
        } else {
//            imageEdgeInsets = UIEdgeInsets(top: 6, left: 0, bottom: 0, right: 0)
//            adjustsImageWhenHighlighted = false
            setTitle(nil, for: .normal)
        }
        setBackgroundImage(UIImage.placeholder(color: UIColor.clear), for: .normal)
        setBackgroundImage(UIImage.placeholder(color: UIColor._systemGray), for: .highlighted)
        setBackgroundImage(UIImage.placeholder(color: UIColor._systemGray), for: .selected)
        
        #if TARGET_IS_EXTENSION
        updateColor(theme: KeyboardModeManager.shared.currentTheme)
        #endif
    }
    
    func updateColor(theme: Theme) {
        setImage(action.image(theme: theme), for: .normal)
        
        switch theme {
        case .light:
            setBackgroundImage(UIImage.placeholder(color: UIColor.clear), for: .normal)
            setTitleColor(.black, for: .normal)
            setTitleColor(.lightGray, for: .disabled)
        case .dark:
            setBackgroundImage(UIImage.placeholder(color: .keyboardCharKeyBackgroundDark), for: .normal)
            setTitleColor(.white, for: .normal)
            setTitleColor(.lightGray, for: .disabled)
        }
    }
}

class ModeSwitchView: UIView, Thematic {
    
    var currentMode: TCKeyboardMode = .encrypt {
        didSet {
            updateCurrentMode()
        }
    }
    
    weak var delegate: ModeSwitchViewDelegate?
    
    private var stackView: UIStackView = {
        let stackView = UIStackView(frame: .zero)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        return stackView
    }()
    
    private var encryptModeButton = ModeSwitchActionButton(type: .custom)
    private var signModeButton = ModeSwitchActionButton(type: .custom)
    private var redpacketModeButton = ModeSwitchActionButton(type: .custom)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        encryptModeButton.action = .encrypt
        
        signModeButton.action = .sign
        
        redpacketModeButton.action = .redpacket
        
        stackView.addArrangedSubview(encryptModeButton)
        stackView.addArrangedSubview(signModeButton)
        stackView.addArrangedSubview(redpacketModeButton)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        encryptModeButton.addTarget(self, action: #selector(modeActionButtonDidClicked(_:)), for: .touchUpInside)
        signModeButton.addTarget(self, action: #selector(modeActionButtonDidClicked(_:)), for: .touchUpInside)
        redpacketModeButton.addTarget(self, action: #selector(modeActionButtonDidClicked(_:)), for: .touchUpInside)
        updateColor(theme: KeyboardModeManager.shared.currentTheme)
    }
    
    @objc
    private func modeActionButtonDidClicked(_ sender: ModeSwitchActionButton) {
        for subview in stackView.arrangedSubviews {
            if let button = subview as? ActionButton {
                button.isSelected = (button === sender)
            }
        }
        delegate?.modeSwitchView(self, modeSwitchButtonDidClicked: sender.action)
    }
    
    private func updateCurrentMode() {
        let index = TCKeyboardMode.allCases.firstIndex(of: currentMode)
        for (subviewIndex, subview) in stackView.arrangedSubviews.enumerated() {
            if let button = subview as? ActionButton {
                button.isSelected = index == subviewIndex
            }
        }
    }
    
    func updateColor(theme: Theme) {
        switch theme {
        case .light:
            backgroundColor = UIColor.keyboardBackgroundLight
        case .dark:
            backgroundColor = UIColor.keyboardCharKeyBackgroundDark
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        encryptModeButton.alignVertical()
        signModeButton.alignVertical()
        redpacketModeButton.alignVertical()
        setNeedsLayout()
    }
}
