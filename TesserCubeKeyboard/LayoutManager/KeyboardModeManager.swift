//
//  KeyboardModeManager.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/2/21.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import ConsolePrint

enum KeyboardMode {
    case typing
    case editingRecipients
    case cannotDecrypt
    case interpretResult
    case editingRedPacket
    
    var keyboardExtraHeight: CGFloat {
        switch self {
        case .typing:
            return 0
        case .editingRecipients:
            return metrics[.contactsBanner]!
        case .cannotDecrypt:
            return metrics[.cannotDecryptBanner]!
        case .interpretResult:
            return metrics[.interpretResultBanner]!
        case .editingRedPacket:
            return metrics[.redPacketBanner]!
        }
    }
}

protocol KeyboardModeListener {
    func update(mode: KeyboardMode)
}

class KeyboardModeManager: NSObject {
    
    static let shared = KeyboardModeManager()
    
    weak var keyboardVC: KeyboardViewController?
//    weak var selectRecipientView: SelectedRecipientView?
    var optionsView: OptionFieldView!
    
    var recommendView: RecommendRecipientsView?
    
    var cannotDecryptView: InterpretFailView?
    
    var interpretResultView: InterpretResultView?
    
    var editingRedPacketViewControllerNaviVC: UIViewController?
    
    var listener: [KeyboardModeListener] = []
    
    var toastAlerter = ToastAlerter()
    
    var decryptedMessage: Message?
    
    var currentTheme: Theme {
        guard let keyboardVC = keyboardVC else { return .light }
        return keyboardVC.darkMode() ? .dark : .light
    }
    
    var mode: KeyboardMode = .typing {
        didSet {
            DispatchQueue.main.async {
                self.updateMode()
                self.listener.forEach { $0.update(mode: self.mode) }
            }
        }
    }
    
    func setupSubViews() {
        optionsView = OptionFieldView(frame: .zero)
        listener.append(optionsView!)
        keyboardVC?.view.insertSubview(optionsView!, belowSubview: keyboardVC!.forwardingView)
        
        optionsView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(keyboardVC!.forwardingView.snp.top)
            make.height.equalTo(metrics[.recipientsBanner]!)
        }
        optionsView.selectedRecipientsView?.delegate = self
        optionsView.actionsView.delegate = self
        optionsView.suggestionView?.delegate = self
    }
    
    private func updateMode() {
        removeRecommendView()
        removeEditingRedPacketView()
        removeCannotDecryptView()
        removeInterpretResultView()
        
        switch mode {
        case .typing:
            optionsView.setFullAccessHintViewVisible(false)
            keyboardVC?.adjustHeight(delta: mode.keyboardExtraHeight)
        case .editingRecipients:
            if let hasAccess = keyboardVC?.hasFullAccess, hasAccess {
                keyboardVC?.adjustHeight(delta: mode.keyboardExtraHeight)
                optionsView.setFullAccessHintViewVisible(false)
                addRecommendView()
            } else {
                optionsView.setFullAccessHintViewVisible(true)
            }
        case .editingRedPacket:
            if let hasAccess = keyboardVC?.hasFullAccess, hasAccess {
                keyboardVC?.adjustHeight(delta: mode.keyboardExtraHeight)
                optionsView.setFullAccessHintViewVisible(false)
                addEditingRedPacketView()
            } else {
                optionsView.setFullAccessHintViewVisible(true)
            }
        case .cannotDecrypt:
            optionsView.setFullAccessHintViewVisible(false)
            keyboardVC?.adjustHeight(delta: mode.keyboardExtraHeight)
            addCannotDecryptView()
        case .interpretResult:
            guard let message = decryptedMessage else { return }
            optionsView.setFullAccessHintViewVisible(false)
            keyboardVC?.adjustHeight(delta: mode.keyboardExtraHeight)
            addInterpretResultView(message: message)
        }
    }
    
    func insertKey(_ key: String) {
        if mode == .editingRecipients, let recipientView = recommendView {
            let inputRecipientTextView = recipientView.recipientInputView
            let tempText = inputRecipientTextView.inputTextField.text ?? ""
            inputRecipientTextView.inputTextField.text = (tempText + key)
            inputRecipientTextView.inputTextField.repositionCursor()
        } else {
            keyboardVC?.textDocumentProxy.insertText(key)
            contextDidChange()
        }
    }
    
    func deleteBackward() {
        if mode == .editingRecipients, let recipientView = recommendView {
            let inputRecipientTextView = recipientView.recipientInputView
            let tempText = inputRecipientTextView.inputTextField.text ?? ""
            if !tempText.isEmpty {
                inputRecipientTextView.inputTextField.text = String(tempText[tempText.startIndex ..< tempText.index(before: tempText.endIndex)])
                inputRecipientTextView.inputTextField.repositionCursor()
            }
        } else {
            keyboardVC?.textDocumentProxy.deleteBackward()
            contextDidChange()
        }
    }
    
    var documentContextBeforeInput: String? {
        if mode == .editingRecipients, let recipientView = recommendView {
            let inputRecipientTextView = recipientView.recipientInputView
            return inputRecipientTextView.inputTextField.text
        } else {
            return keyboardVC?.textDocumentProxy.documentContextBeforeInput
        }
    }
    
    func contextDidChange() {
        var input = documentContextBeforeInput
        var latestWord = keyboardVC?.lastWord ?? ""
        if let selectedText = keyboardVC?.textDocumentProxy.selectedText {
            latestWord = selectedText
            input = selectedText
        }

        // Auto-correct and user lexicon
        // And without default suggestions. Should append manually.
        let suggesions = SuggestHelper.getSuggestion(latestWord, lexicon: keyboardVC?.lexicon)

        // Aysnc suggestion depend on input string
        if let wordPredictor = WordSuggestionService.shared.wordPredictor,
        !wordPredictor.needLoadNgramData, let input = input {
            wordPredictor.suggestWords(for: input) { [weak self] words in
                let predictWords = suggesions + words.map { $0.0 }
                let isPeriodSuffix = input.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix(".")
                let words = (predictWords.isEmpty && latestWord.isEmpty) || isPeriodSuffix ? SuggestHelper.defaultSuggestions : predictWords

                self?.optionsView.suggestionView?.updateSuggesions(NSOrderedSet(array: words).array as! [String])
            }
        } else {
            let words = suggesions.isEmpty ? SuggestHelper.defaultSuggestions : suggesions
            optionsView.suggestionView?.updateSuggesions(NSOrderedSet(array: words).array as! [String])
        }
    }
}

// MARK: RecommendView
extension KeyboardModeManager {
    func addRecommendView() {
        if recommendView == nil {
            
            recommendView = RecommendRecipientsView(frame: .zero)
            recommendView?.updateColor(theme: currentTheme)
            recommendView?.delegate = self
            recommendView?.optionFieldView = optionsView
            keyboardVC?.view.insertSubview(recommendView!, belowSubview: optionsView)
            
            recommendView?.snp.makeConstraints{ make in
                make.leading.trailing.top.equalToSuperview()
                make.height.equalTo(metrics[.contactsBanner]!)
            }
        }
    }
    
    func removeRecommendView() {
        if recommendView != nil {
            recommendView?.removeFromSuperview()
            recommendView = nil
        }
    }
}

extension KeyboardModeManager: RecommendRecipientsViewDelegate {
    func recommendRecipientsView(_ view: RecommendRecipientsView, didSelect contactInfo: FullContactInfo) {
        let selectedData = optionsView.selectedContacts
        if selectedData.contains(where: { (data) -> Bool in
            return data.contact.id == contactInfo.contact.id
        }) {
            // This should not happen
            print(" This should not happen, account: \(contactInfo.contact.name)")
        } else {
            optionsView.addSelectedRecipient(contactInfo)
        }
    }
}

extension KeyboardModeManager: SelectedRecipientViewDelegate {
    func selectedRecipientView(_ view: SelectedRecipientView, didClick contactInfo: FullContactInfo) {
        optionsView.updateLayout(mode: mode)
        recommendView?.reloadRecipients()
    }
}

// MARK: Cannot decrypt view
extension KeyboardModeManager: InterpretFailViewDelegate {
    func addCannotDecryptView() {
        if cannotDecryptView == nil {
            
            cannotDecryptView = InterpretFailView(frame: .zero)
            cannotDecryptView?.delegate = self
            keyboardVC?.view.insertSubview(cannotDecryptView!, belowSubview: optionsView)
            
            cannotDecryptView?.snp.makeConstraints{ make in
                make.leading.trailing.top.equalToSuperview()
                make.height.equalTo(metrics[.cannotDecryptBanner]!)
            }
        }
    }
    
    func removeCannotDecryptView() {
        if cannotDecryptView != nil {
            cannotDecryptView?.removeFromSuperview()
            cannotDecryptView = nil
        }
    }
    
    func interpretFailView(_ view: InterpretFailView, didClickedClose button: UIButton) {
        mode = .typing
    }
}

// MARK: Interpret result view
extension KeyboardModeManager: InterpretResultViewViewDelegate {
    
    func addInterpretResultView(message: Message) {
        if interpretResultView == nil {
            
            interpretResultView = InterpretResultView(frame: .zero)
            interpretResultView?.delegate = self
            interpretResultView?.message = message
            keyboardVC?.view.insertSubview(interpretResultView!, belowSubview: optionsView)
            
            interpretResultView?.snp.makeConstraints{ make in
                make.leading.trailing.top.equalToSuperview()
                make.height.equalTo(metrics[.interpretResultBanner]!)
            }
        }
    }
    
    func removeInterpretResultView() {
        if interpretResultView != nil {
            interpretResultView?.removeFromSuperview()
            interpretResultView = nil
        }
    }
    
    func interpretResultViewView(_ view: InterpretResultView, didClickedClose button: UIButton) {
        mode = .typing
    }
}

extension KeyboardModeManager: ActionsViewDelegate {
    func actionsView(_ view: ActionsView, didClick action: ActionType, button: ActionButton) {
        switch action {
        case .encrypt:
            guard !optionsView.selectedContacts.isEmpty else {
                toastAlerter.alert(message: L10n.Keyboard.Alert.noSelectedRecipient, in: keyboardVC!.view)
                return
            }
            guard let originContent = keyboardVC?.textDocumentProxy.documentContextBeforeInput, !originContent.isEmpty else { return }
            
            let recipientKeys = optionsView.selectedContacts.map { $0.keys }.flatMap { $0 }
            do {
                var signatureKey: TCKey?
                if case .automatic = KeyboardPreference.kMessageDigitalSignatureSettings {
                    signatureKey = ProfileService.default.defaultSignatureKey
                }

                let message = try ProfileService.default.encryptMessage(originContent, signatureKey: signatureKey, recipients: recipientKeys)

                keyboardVC?.removeAllBeforeContent()
                keyboardVC?.textDocumentProxy.insertText(message.encryptedMessage)
                optionsView.removeAllSelectedRecipients()
            } catch {
                consolePrint(error.localizedDescription)
                toastAlerter.alert(message: error.localizedDescription, in: keyboardVC!.view)
            }
            
            break
        case .redPacket:
            guard !optionsView.selectedContacts.isEmpty else {
                //TODO: i18n
                toastAlerter.alert(message: L10n.Keyboard.Alert.noSelectedRecipient, in: keyboardVC!.view)
                return
            }
            button.isSelected = !button.isSelected
            Self.shared.mode = button.isSelected ? .editingRedPacket : .editingRecipients
            return;
        case .modeChange:
            break
        }
    }
}

extension KeyboardModeManager: SuggesionViewDelegate {
    func suggestionView(_ view: SuggestionView, didClick suggest: String) {
        keyboardVC?.replaceLastWord(by: suggest)
        keyboardVC?.textDocumentProxy.insertText(" ")
        keyboardVC?.contextChanged()
    }
}

// MARK: Copy
extension KeyboardModeManager {
    func checkPasteboard() {
        if let pastedString = UIPasteboard.general.string, KeyFactory.isValidMessage(from: pastedString) {
            KeyboardInterpretor.interpretMessage(pastedString) { (success, error, result) in
                KeyboardModeManager.shared.handleInterpretResult(success: success, error: error, result: result)
                
            }
        }
    }
}

// MARK: Interpret result handling
extension KeyboardModeManager {
    func handleInterpretResult(success: Bool, error: Error?, result: Message?) {
        guard let keyboardVC = keyboardVC else { return }
        if success, let resultMessage = result {
            decryptedMessage = resultMessage
            mode = .interpretResult
        } else {
            consolePrint(error?.localizedDescription)
            switch error {
            case (let tcError as TCError):
                switch tcError {
                case .pgpKeyError(let reason):
                    switch reason {
                    case .invalidKeyFormat:
                        self.toastAlerter.alert(message: L10n.Keyboard.Alert.noEncryptedText, in: keyboardVC.view)
                    default:
                        break
                    }
                default:
                    toastAlerter.alert(message: tcError.localizedDescription, in: keyboardVC.view)
                    return
                }
            default:
                toastAlerter.alert(message: error?.localizedDescription ?? L10n.Common.Alert.unknownError, in: keyboardVC.view)
            }
        }
    }
}
