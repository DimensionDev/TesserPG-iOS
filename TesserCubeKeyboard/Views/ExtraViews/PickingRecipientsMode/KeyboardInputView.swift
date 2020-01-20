//
//  RecipientInputView.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/2/25.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit

extension NSNotification.Name {
    static let KeyboardTextFieldIsSelected = NSNotification.Name(rawValue: "com.Sujitech.TesserCube.keyboard.KeyboardTextFieldIsSelected")
}

protocol KeyboardInputTextFieldDelegate: class {
    func receipientTextField(_ textField: KeyboardInputTextField, textDidChange text: String?)
}

class KeyboardInputTextField: UITextField, UITextInputDelegate {
    
    weak var customDelegate: KeyboardInputTextFieldDelegate?
    
    var textFieldIsSelected: Bool = false {
        didSet {
            cursorView.isHidden = !textFieldIsSelected
            if textFieldIsSelected {
                NotificationCenter.default.post(name: NSNotification.Name.KeyboardTextFieldIsSelected, object: self, userInfo: nil)
            }
            repositionCursor()
        }
    }
    
    var textFont = FontFamily.SFProDisplay.regular.font(size: 16) {
        didSet {
            font = textFont
        }
    }
    
    private var cursorView: UIView = {
        let cursor = UIView(frame: .zero)
        cursor.addOpacityAnimation()
        return cursor
    }()
    
    var leftInset: CGFloat = 12
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveTextFieldIsSelected), name: NSNotification.Name.KeyboardTextFieldIsSelected, object: nil)
        inputDelegate = self
        cursorView.backgroundColor = tintColor
        cursorView.isHidden = true
        addSubview(cursorView)
        
        repositionCursor()
    }
    
    @objc
    private func didReceiveTextFieldIsSelected(_ noti: Notification) {
        guard let tf = noti.object as? KeyboardInputTextField else { return }
        if tf === self {
            
        } else {
            // Another KeyboardTextInputView selected, deselecte this one
            if tf.textFieldIsSelected {
                self.textFieldIsSelected = false
            }
        }
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
        if let lastLetterPosition = position(from: endOfDocument, offset: 0) {
            let lastCaretRect = caretRect(for: lastLetterPosition)
            cursorView.frame = lastCaretRect.offsetBy(dx: leftInset, dy: 0)
        }
        customDelegate?.receipientTextField(self, textDidChange: text)
    }
    
    @objc
    private func didReceiveTextChangeNoti(_ noti: Notification) {
        guard let tf = noti.object as? KeyboardInputTextField, tf == self else { return }
        repositionCursor()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        textFieldIsSelected = true
        super.touchesBegan(touches, with: event)
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let oRect = super.textRect(forBounds: bounds)
        return oRect.insetBy(dx: leftInset, dy: 0)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let oRect = super.editingRect(forBounds: bounds)
        return oRect.insetBy(dx: leftInset, dy: 0)
    }

}

class KeyboardInputView: UIView, Thematic {
    
    static let minimumWidth: CGFloat = 140
    static let minimumHeight: CGFloat = 32
    
    var inputTextField: KeyboardInputTextField!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configUI()
    }
    
    private func configUI() {
        
        inputTextField = KeyboardInputTextField(frame: CGRect(x: 0, y: 0, width: KeyboardInputView.minimumWidth, height: KeyboardInputView.minimumHeight))
        inputTextField.borderStyle = .none
        inputTextField.backgroundColor = .clear
        inputTextField.returnKeyType = .next
//        inputTextField.layer.cornerRadius = 16
//        inputTextField.layer.masksToBounds = true
//        inputTextField.clearButtonMode = .always
        
        addSubview(inputTextField)
        
//        layer.cornerRadius = 16
//        layer.masksToBounds = true
        updateColor(theme: .light)
        
        inputTextField.snp.makeConstraints { make in
            make.edges.equalToSuperview()
//            make.width.equalTo(KeyboardInputView.minimumWidth)
//            make.height.equalTo(KeyboardInputView.minimumHeight)
        }
        
//        snp.makeConstraints { make in
//            make.width.equalTo(inputTextField.snp.width)
//        }
        
        #if TARGET_IS_EXTENSION
        updateColor(theme: KeyboardModeManager.shared.currentTheme)
        #endif
    }
    
    func updateColor(theme: Theme) {
        switch theme {
        case .light:
            inputTextField.textColor = .black
        case .dark:
            inputTextField.textColor = .white
        }
        
    }
}
