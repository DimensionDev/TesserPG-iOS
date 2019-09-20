//
//  RecipientInputView.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/2/25.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit

protocol ReceipientTextFieldDelegate: class {
    func receipientTextField(_ textField: ReceipientTextField, textDidChange text: String?)
}

class ReceipientTextField: UITextField, UITextInputDelegate {
    
    weak var customDelegate: ReceipientTextFieldDelegate?
    
    var textFieldIsSelected: Bool = false {
        didSet {
            cursorView.isHidden = !textFieldIsSelected
        }
    }
    
    var textFont = FontFamily.SFProDisplay.regular.font(size: 16) {
        didSet {
            font = textFont
        }
    }
    
    private var cursorView: UIView = {
        let cursor = UIView(frame: CGRect(x: ReceipientTextField.widthInset, y: 4, width: 2, height: 24))
        cursor.addOpacityAnimation()
        return cursor
    }()
    
    private static let widthInset: CGFloat = 12
    
    override var canBecomeFirstResponder: Bool {
        // This property is called only when user try to tap this UITextField, right?
        textFieldIsSelected = true
        return false
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configUI()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func configUI() {
        font = FontFamily.SFProDisplay.regular.font(size: 16)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveTextChangeNoti(_:)), name: UITextField.textDidChangeNotification, object: nil)
        inputDelegate = self
        cursorView.backgroundColor = tintColor
        cursorView.isHidden = true
        addSubview(cursorView)
    }
    
    func selectionWillChange(_ textInput: UITextInput?) {
        
    }
    
    func selectionDidChange(_ textInput: UITextInput?) {
        
    }
    
    func textWillChange(_ textInput: UITextInput?) {
        
    }
    
    func textDidChange(_ textInput: UITextInput?) {
        repositionCursor()
    }
    
    func repositionCursor() {
        let oFrame = cursorView.frame
        let textWidth = NSString(string: text ?? "").boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: bounds.size.height), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: textFont], context: nil).width
        cursorView.frame = CGRect(x: textWidth + ReceipientTextField.widthInset, y: oFrame.origin.y, width: oFrame.size.width, height: oFrame.size.height)
        customDelegate?.receipientTextField(self, textDidChange: text)
    }
    
    @objc
    private func didReceiveTextChangeNoti(_ noti: Notification) {
        guard let tf = noti.object as? ReceipientTextField, tf == self else { return }
        repositionCursor()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        textFieldIsSelected = true
        super.touchesBegan(touches, with: event)
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let oRect = super.textRect(forBounds: bounds)
        return oRect.insetBy(dx: ReceipientTextField.widthInset, dy: 0)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let oRect = super.editingRect(forBounds: bounds)
        return oRect.insetBy(dx: ReceipientTextField.widthInset, dy: 0)
    }

}

class RecipientInputView: UIView, Thematic {
    
    static let minimumWidth: CGFloat = 140
    static let minimumHeight: CGFloat = 32
    
    var inputTextField: ReceipientTextField!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configUI()
    }
    
    private func configUI() {
        
        inputTextField = ReceipientTextField(frame: CGRect(x: 0, y: 0, width: RecipientInputView.minimumWidth, height: RecipientInputView.minimumHeight))
        inputTextField.borderStyle = .none
        inputTextField.backgroundColor = .white
        inputTextField.returnKeyType = .next
        inputTextField.layer.cornerRadius = 16
        inputTextField.layer.masksToBounds = true
        inputTextField.clearButtonMode = .always
        
        addSubview(inputTextField)
        
        layer.cornerRadius = 16
        layer.masksToBounds = true
        updateColor(theme: .light)
        
        inputTextField.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(RecipientInputView.minimumWidth)
            make.height.equalTo(RecipientInputView.minimumHeight)
        }
        
        snp.makeConstraints { make in
            make.width.equalTo(inputTextField.snp.width)
        }
        
        updateColor(theme: KeyboardModeManager.shared.currentTheme)
    }
    
    func updateColor(theme: Theme) {
        switch theme {
        case .light:
            inputTextField.backgroundColor = .white
            inputTextField.textColor = .black
        case .dark:
            inputTextField.backgroundColor = .keyboardCharKeyBackgroundDark
            inputTextField.textColor = .white
        }
        
    }
}
