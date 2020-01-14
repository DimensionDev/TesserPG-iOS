//
//  KeyboardMultiLineInputView.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 12/27/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit

protocol KeyboardTextViewDelegate: class {
    func keyboardTextView(_ textView: KeyboardTextView, textDidChange text: String?)
}

class KeyboardTextView: UITextView, UITextInputDelegate {
    
    weak var customDelegate: KeyboardTextViewDelegate?
    
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
        let cursor = UIView(frame: CGRect(x: KeyboardTextView.widthInset, y: 7, width: 2, height: 21))
        cursor.addOpacityAnimation()
        return cursor
    }()
    
    private static let widthInset: CGFloat = 4
    
    override var canBecomeFirstResponder: Bool {
        // This property is called only when user try to tap this UITextField, right?
        textFieldIsSelected = true
        return false
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
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
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveTextChangeNoti(_:)), name: UITextView.textDidChangeNotification, object: nil)
        inputDelegate = self
        cursorView.backgroundColor = tintColor
        cursorView.isHidden = true
        addSubview(cursorView)
    }
    
    func selectionWillChange(_ textInput: UITextInput?) {
        
    }
    
    func selectionDidChange(_ textInput: UITextInput?) {
        repositionCursor()
    }
    
    func textWillChange(_ textInput: UITextInput?) {
        
    }
    
    func textDidChange(_ textInput: UITextInput?) {
        repositionCursor()
    }
    
    func repositionCursor() {
        if let lastLetterPosition = position(from: endOfDocument, offset: 0) {
            let lastCaretRect = caretRect(for: lastLetterPosition)
            cursorView.frame = lastCaretRect
            scrollRectToVisible(lastCaretRect, animated: true)
        }
        
        customDelegate?.keyboardTextView(self, textDidChange: text)
    }
    
    @objc
    private func didReceiveTextChangeNoti(_ noti: Notification) {
        guard let tf = noti.object as? KeyboardTextView, tf == self else { return }
        repositionCursor()
    }
}

class KeyboardMultiLineInputView: UIView, Thematic {
    
    static let minimumWidth: CGFloat = 140
    static let minimumHeight: CGFloat = 32
    
    var inputTextField: KeyboardTextView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configUI()
    }
    
    private func configUI() {
        
        inputTextField = KeyboardTextView(frame: CGRect(x: 0, y: 0, width: KeyboardInputView.minimumWidth, height: KeyboardInputView.minimumHeight), textContainer: nil)
//        inputTextField.borderStyle = .none
        inputTextField.backgroundColor = .white
        inputTextField.returnKeyType = .next
//        inputTextField.layer.cornerRadius = 16
//        inputTextField.layer.masksToBounds = true
//        inputTextField.clearButtonMode = .never
        
        addSubview(inputTextField)
        
//        layer.cornerRadius = 16
//        layer.masksToBounds = true
        updateColor(theme: .light)
        
        inputTextField.snp.makeConstraints { make in
            make.edges.equalToSuperview()
//            make.leading.top.bottom.equalToSuperview()
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
            inputTextField.backgroundColor = .white
            inputTextField.textColor = .black
        case .dark:
            inputTextField.backgroundColor = .keyboardCharKeyBackgroundDark
            inputTextField.textColor = .white
        }
        
    }
}
