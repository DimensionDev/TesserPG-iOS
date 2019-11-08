//
//  ActionsView.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/3/4.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit

protocol ActionsViewDelegate: class {
    func actionsView(_ view: ActionsView, didClick action: ActionType, button: ActionButton)
}

enum ActionType {
    case encrypt
    case redPacket
    case modeChange
    
    func disabledImage(theme: Theme) -> UIImage? {
        switch self {
        default:
            return nil
        }
    }
    
    func image(theme: Theme) -> UIImage {
        switch theme {
        case .light:
            switch self {
            case .encrypt:
                return #imageLiteral(resourceName: "button_lock_normal")
            case .redPacket:
                return #imageLiteral(resourceName: "button_interpret_normal")
            case .modeChange:
                return #imageLiteral(resourceName: "button_modeChange_icon")
            }
        case .dark:
            switch self {
            case .encrypt:
                return #imageLiteral(resourceName: "button_lock_normal_dark")
            case .redPacket:
                return #imageLiteral(resourceName: "button_interpret_normal_dark")
            case .modeChange:
                return #imageLiteral(resourceName: "button_modeChange_icon_dark")
            }
        }
    }
    
    func highlightImage(theme: Theme) -> UIImage? {
        switch theme {
        case .light:
            switch self {
            case .modeChange:
                return #imageLiteral(resourceName: "button_modeChange_icon_selected")
            default:
                return nil
            }
        case .dark:
            switch self {
            case .modeChange:
                return #imageLiteral(resourceName: "button_modeChange_icon_dark_selected")
            default:
                return nil
            }
        }
        
    }
    
    func selectedImage(theme: Theme) -> UIImage? {
        switch theme {
        case .light:
            switch self {
            case .modeChange:
                return #imageLiteral(resourceName: "button_modeChange_icon_selected")
            default:
                return nil
            }
        case .dark:
            switch self {
            case .modeChange:
                return #imageLiteral(resourceName: "button_modeChange_icon_dark_selected")
            default:
                return nil
            }
        }
    }
    
    var title: String? {
        switch self {
        case .encrypt:
            return L10n.Keyboard.Button.encrypt
        case .redPacket:
            return "Red Packet" //TODO: i18n
        case .modeChange:
            return nil
        }
    }
}

class ActionsView: UIView, Thematic {
    
    weak var delegate: ActionsViewDelegate?
    
    var encryptButton: ActionButton?
    var redPacketButton: ActionButton?
    var modeChangeButton: ActionButton?
    
    var actions: [ActionType] = [.modeChange] {
        didSet {
            reloadActionButtons()
        }
    }
    
    var neededWidth: CGFloat {
        let buttonsWidth = CGFloat(actions.count) * ActionButton.defaultWidth
        let separatorWidth = CGFloat(actions.count + 1) * SeparatorView.separatorWidth
        return buttonsWidth + separatorWidth
    }
    
    private var stackView: UIStackView!
    
    convenience init(actions: [ActionType]) {
        self.init(frame: .zero)
        self.actions = actions
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
//        backgroundColor = .purple
        createStackView()
        setupConstraints()
    }
    
    private func createStackView() {
        stackView = UIStackView(frame: .zero)
        stackView.axis = .horizontal
        stackView.alignment = .bottom
        stackView.distribution = .fill
        stackView.spacing = 0
        addSubview(stackView)
    }
    
    
    
    private func setupConstraints() {
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func updateColor(theme: Theme) {
        switch theme {
        case .light:
            backgroundColor = .keyboardBackgroundLight
        case .dark:
            backgroundColor = .keyboardBackgroundDark
        }
    }
    
    private func reloadActionButtons() {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for action in actions {
            let separator = SeparatorView()
            stackView.addArrangedSubview(separator)
            separator.snp.makeConstraints { make in
                make.width.equalTo(SeparatorView.separatorWidth)
                make.height.equalToSuperview()
            }


            let button = ActionButton(type: .custom)
            button.action = action

            var buttonSize: CGSize
            switch action {
            case .encrypt:
                encryptButton = button
                buttonSize = ActionButton.expandSize
            case .redPacket:
                redPacketButton = button
                buttonSize = ActionButton.expandSize
            case .modeChange:
                modeChangeButton = button
                buttonSize = ActionButton.defaultSize
            }

            stackView.addArrangedSubview(button)
            button.snp.makeConstraints { make in
                make.size.equalTo(buttonSize)
            }

            button.addTarget(self, action: #selector(actionButtonDidClicked(_:)), for: .touchUpInside)
        }
    }

    func resetButtonStatus() {
        for subView in stackView.arrangedSubviews {
            if let button = subView as? UIButton {
                button.isSelected = false
            }
        }
    }
    
    func setButtonsTitleVisible(_ visible: Bool) {
        encryptButton?.isTitleVisible = visible
        redPacketButton?.isTitleVisible = visible
        
        let width = visible ? ActionButton.expandSize : ActionButton.defaultSize;
        encryptButton?.snp.remakeConstraints { make in
            make.size.equalTo(width)
        }
        redPacketButton?.snp.remakeConstraints { make in
            make.size.equalTo(width)
        }
    }
    
    @objc
    private func actionButtonDidClicked(_ sender: ActionButton) {
        switch sender.action {
        case .modeChange:
            sender.isSelected = !sender.isSelected
            KeyboardModeManager.shared.mode = sender.isSelected ? .editingRecipients : .typing
        case .encrypt:
            delegate?.actionsView(self, didClick: sender.action, button: sender)
        case .redPacket:
            delegate?.actionsView(self, didClick: sender.action, button: sender)
            return
        }
    }
}
