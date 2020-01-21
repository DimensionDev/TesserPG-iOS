//
//  KeyboardModeManager.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/2/21.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import ConsolePrint
import RxSwift
import RxCocoa

enum KeyboardMode {
    case typing
    case command(mode: TCKeyboardMode)
    case cannotDecrypt
    case interpretResult
    case editingRedPacket
    
    var keyboardExtraHeight: CGFloat {
        switch self {
        case .typing:
            return 0
        case .command(let mode):
            let provider = TCKeyboardModeSwitchHelper.modeProviderType[mode]
            return provider!.extraHeight
        case .cannotDecrypt:
            return metrics[.cannotDecryptBanner]!
        case .interpretResult:
            return metrics[.interpretResultBanner]!
        case .editingRedPacket:
            return metrics[.redPacketBanner]!
        }
    }
}

extension KeyboardMode {
    var actions: [ActionType] {
        return [.modeChange]
//        switch self {
//        case .typing,
//             .cannotDecrypt,
//             .interpretResult:
//            return [.modeChange]
//        case .editingRecipients,
//             .editingRedPacket:
//            return [.encrypt, .redPacket, .modeChange]
//        }
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
    
//    var recommendView: RecommendRecipientsView?
    
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
    
    var tcKeyboardModeContainer: TCKeyboardModeContainer?
    
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
//        removeRecommendView()
        removeContainerView()
        removeEditingRedPacketView()
        removeCannotDecryptView()
        removeInterpretResultView()
        
        switch mode {
        case .typing:
            optionsView.setFullAccessHintViewVisible(false)
            keyboardVC?.adjustHeight(delta: mode.keyboardExtraHeight)
        case .command(let tcKeyboardMode):
//            if let hasAccess = keyboardVC?.hasFullAccess, hasAccess {
//                keyboardVC?.adjustHeight(delta: mode.keyboardExtraHeight)
//                optionsView.setFullAccessHintViewVisible(false)
//                addRecommendView()
//            } else {
//                optionsView.setFullAccessHintViewVisible(true)
//            }
            if let hasAccess = keyboardVC?.hasFullAccess, hasAccess {
                keyboardVC?.adjustHeight(delta: mode.keyboardExtraHeight)
                optionsView.setFullAccessHintViewVisible(false)
                addContainerView()
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
        if case let .command(tcKeyboardMode) = mode, tcKeyboardMode == .encrypt, let container = tcKeyboardModeContainer {
            if let topNaviVC = container.topmostViewController as? UINavigationController {
                if let encryptVC = topNaviVC.topViewController as? EncryptViewController {
                    let inputRecipientTextView = encryptVC.contentInputView
                    let tempText = inputRecipientTextView.inputTextField.text ?? ""
                    inputRecipientTextView.inputTextField.text = (tempText + key)
                    return
                }
                if let selectRecipientVC = topNaviVC.topViewController as? SelectRecipientViewController {
                    let inputRecipientTextView = selectRecipientVC.selectRecipientView?.recipientInputView
                    let tempText = inputRecipientTextView?.inputTextField.text ?? ""
                    inputRecipientTextView?.inputTextField.text = (tempText + key)
                    inputRecipientTextView?.inputTextField.repositionCursor()
                    return
                }
                if let signVC = topNaviVC.topViewController as? SignViewController {
                    let inputRecipientTextView = signVC.contentInputView
                    let tempText = inputRecipientTextView.inputTextField.text ?? ""
                    inputRecipientTextView.inputTextField.text = (tempText + key)
                    return
                }
                if let redpacketVC = topNaviVC.topViewController as? RedPacketKeyboardViewController {
                    guard let editRedPacketVC = redpacketVC.children.first as? EditingRedPacketViewController else {
                        return
                    }
                    for cell in editRedPacketVC.tableView.visibleCells {
                        if let amountCell = cell as? KeyboardInputRedPacketAmoutCell, amountCell.amountTextField.inputTextField.textFieldIsSelected {
                            if amountCell.textField(amountCell.amountTextField.inputTextField, shouldChangeCharactersIn: NSMakeRange(amountCell.amountTextField.inputTextField.text?.count ?? 0, 0), replacementString: key) {
                                amountCell.amountTextField.inputTextField.text = (amountCell.amountTextField.inputTextField.text ?? "") + key
                            }
                            amountCell.amountTextField.inputTextField.repositionCursor()
                        }
                        if let senderCell = cell as? KeyboardInputRedPacketSenderCell, senderCell.nameTextField.inputTextField.textFieldIsSelected {
                            senderCell.nameTextField.inputTextField.text = (senderCell.nameTextField.inputTextField.text ?? "") + key
                            senderCell.nameTextField.inputTextField.repositionCursor()
                            editRedPacketVC.viewModel.name.accept(senderCell.nameTextField.inputTextField.text ?? "")
                        }
                        if let messageCell = cell as? KeyboardInputRedPacketMessageCell, messageCell.messageTextField.inputTextField.textFieldIsSelected {
                            messageCell.messageTextField.inputTextField.text = (messageCell.messageTextField.inputTextField.text ?? "") + key
                            messageCell.messageTextField.inputTextField.repositionCursor()
                            editRedPacketVC.viewModel.message.accept(messageCell.messageTextField.inputTextField.text ?? "")
                        }
                    }
                    return
                }
            }
        }
        keyboardVC?.textDocumentProxy.insertText(key)
        contextDidChange()
    }
    
    func deleteBackward() {
        if case let .command(tcKeyboardMode) = mode, tcKeyboardMode == .encrypt, let container = tcKeyboardModeContainer {
            if let topNaviVC = container.topmostViewController as? UINavigationController {
                if let encryptVC = topNaviVC.topViewController as? EncryptViewController {
                    let inputRecipientTextView = encryptVC.contentInputView
                    let tempText = inputRecipientTextView.inputTextField.text ?? ""
                    if !tempText.isEmpty {
                        inputRecipientTextView.inputTextField.text = String(tempText[tempText.startIndex ..< tempText.index(before: tempText.endIndex)])
//                        inputRecipientTextView.inputTextField.repositionCursor()
                    }
                    return
                }
                if let selectRecipientVC = topNaviVC.topViewController as? SelectRecipientViewController {
                    let inputRecipientTextView = selectRecipientVC.selectRecipientView?.recipientInputView
                    let tempText = inputRecipientTextView?.inputTextField.text ?? ""
                    if !tempText.isEmpty {
                        inputRecipientTextView?.inputTextField.text = String(tempText[tempText.startIndex ..< tempText.index(before: tempText.endIndex)])
                        inputRecipientTextView?.inputTextField.repositionCursor()
                    }
                    return
                }
                if let signVC = topNaviVC.topViewController as? SignViewController {
                    let inputRecipientTextView = signVC.contentInputView
                    let tempText = inputRecipientTextView.inputTextField.text ?? ""
                    if !tempText.isEmpty {
                        inputRecipientTextView.inputTextField.text = String(tempText[tempText.startIndex ..< tempText.index(before: tempText.endIndex)])
//                        inputRecipientTextView.inputTextField.repositionCursor()
                    }
                }
                if let redpacketVC = topNaviVC.topViewController as? RedPacketKeyboardViewController {
                    guard let editRedPacketVC = redpacketVC.children.first as? EditingRedPacketViewController else {
                        return
                    }
                    for cell in editRedPacketVC.tableView.visibleCells {
                        if let amountCell = cell as? KeyboardInputRedPacketAmoutCell,
                            amountCell.amountTextField.inputTextField.textFieldIsSelected {
                            let tempText = amountCell.amountTextField.inputTextField.text ?? ""
                            amountCell.amountTextField.inputTextField.text = String(tempText[tempText.startIndex ..< tempText.index(before: tempText.endIndex)])
                            amountCell.amountTextField.inputTextField.repositionCursor()
                        }
                        if let senderCell = cell as? KeyboardInputRedPacketSenderCell,
                            senderCell.nameTextField.inputTextField.textFieldIsSelected {
                            let tempText = senderCell.nameTextField.inputTextField.text ?? ""
                            if !tempText.isEmpty {
                                senderCell.nameTextField.inputTextField.text = String(tempText[tempText.startIndex ..< tempText.index(before: tempText.endIndex)])
                            }
                            senderCell.nameTextField.inputTextField.repositionCursor()
                        }
                        if let messageCell = cell as? KeyboardInputRedPacketMessageCell, messageCell.messageTextField.inputTextField.textFieldIsSelected {
                            let tempText = messageCell.messageTextField.inputTextField.text ?? ""
                            if !tempText.isEmpty {
                                messageCell.messageTextField.inputTextField.text = String(tempText[tempText.startIndex ..< tempText.index(before: tempText.endIndex)])
                            }
                            messageCell.messageTextField.inputTextField.repositionCursor()
                        }
                    }
                    return
                }
            }
        }
        keyboardVC?.textDocumentProxy.deleteBackward()
        contextDidChange()
    }
    
    var documentContextBeforeInput: String? {
        if case let .command(tcKeyboardMode) = mode, tcKeyboardMode == .encrypt, let container = tcKeyboardModeContainer {
            if let topNaviVC = container.topmostViewController as? UINavigationController {
                if let encryptVC = topNaviVC.topViewController as? EncryptViewController {
                    return encryptVC.contentInputView.inputTextField.text
                }
                if let selectRecipientVC = topNaviVC.topViewController as? SelectRecipientViewController {
                    return selectRecipientVC.selectRecipientView?.recipientInputView.inputTextField.text
                }
                if let signVC = topNaviVC.topViewController as? SignViewController {
                    return signVC.contentInputView.inputTextField.text
                }
                if let redpacketVC = topNaviVC.topViewController as? RedPacketKeyboardViewController,
                    let editRedPacketVC = redpacketVC.children.first as? EditingRedPacketViewController {
                    for cell in editRedPacketVC.tableView.visibleCells {
                        if let amountCell = cell as? KeyboardInputRedPacketAmoutCell, amountCell.amountTextField.inputTextField.textFieldIsSelected {
                            return amountCell.amountTextField.inputTextField.text
                        }
                        if let senderCell = cell as? KeyboardInputRedPacketSenderCell,
                            senderCell.nameTextField.inputTextField.textFieldIsSelected {
                            return senderCell.nameTextField.inputTextField.text
                        }
                        if let messageCell = cell as? KeyboardInputRedPacketMessageCell, messageCell.messageTextField.inputTextField.textFieldIsSelected {
                            return messageCell.messageTextField.inputTextField.text
                        }
                    }
                }
            }
        }
        return keyboardVC?.textDocumentProxy.documentContextBeforeInput
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
    
    func addContainerView() {
        if tcKeyboardModeContainer == nil {
            tcKeyboardModeContainer = TCKeyboardModeContainer(mode: .encrypt)
        }
        keyboardVC?.view.insertSubview(tcKeyboardModeContainer!.containerView, belowSubview: optionsView)
        
        tcKeyboardModeContainer!.containerView.snp.makeConstraints{ make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(metrics[.contactsBanner]!)
        }
    }
    
    func removeContainerView() {
        if tcKeyboardModeContainer != nil {
            tcKeyboardModeContainer!.containerView.removeFromSuperview()
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
        if let encryptNaviVC = tcKeyboardModeContainer?.topmostViewController as? UINavigationController {
            if let selectRecipientVC = encryptNaviVC.topViewController as? SelectRecipientViewController {
                selectRecipientVC.navigationItem.rightBarButtonItem?.isEnabled = !optionsView.selectedContacts.isEmpty
            }
        }
    }
}

 extension KeyboardModeManager: SelectedRecipientViewDelegate {
     func selectedRecipientView(_ view: SelectedRecipientView, didClick contactInfo: FullContactInfo) {
         if let encryptNaviVC = tcKeyboardModeContainer?.topmostViewController as? UINavigationController {
             if let selectRecipientVC = encryptNaviVC.topViewController as? SelectRecipientViewController {
                 selectRecipientVC.selectRecipientView?.reloadRecipients()
                 selectRecipientVC.navigationItem.rightBarButtonItem?.isEnabled = !optionsView.selectedContacts.isEmpty
             }
         }
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
            button.isSelected = !button.isSelected
//            Self.shared.mode = button.isSelected ? .editingRedPacket : .command
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

extension KeyboardModeManager: SelectRecipientViewControllerDelegate {
    func selectRecipientViewController(_ viewController: SelectRecipientViewController, rawMessage: String, didClick sendBarButton: UIBarButtonItem) {
        guard !optionsView.selectedContacts.isEmpty else {
            toastAlerter.alert(message: L10n.Keyboard.Alert.noSelectedRecipient, in: keyboardVC!.view)
            return
        }
        
        let recipientKeys = optionsView.selectedContacts.map { $0.keys }.flatMap { $0 }
        do {
            var signatureKey: TCKey?
            if case .automatic = KeyboardPreference.kMessageDigitalSignatureSettings {
                signatureKey = ProfileService.default.defaultSignatureKey
            }

            let message = try ProfileService.default.encryptMessage(rawMessage, signatureKey: signatureKey, recipients: recipientKeys)

            keyboardVC?.textDocumentProxy.insertText(message.encryptedMessage)
            optionsView.removeAllSelectedRecipients()
            
            mode = .typing
        } catch {
            consolePrint(error.localizedDescription)
            toastAlerter.alert(message: error.localizedDescription, in: keyboardVC!.view)
        }
    }
}

extension KeyboardModeManager: SignViewControllerDelegate {
    func signViewController(_ viewController: SignViewController, didClick sendBarButton: UIBarButtonItem) {
        guard let originContent = documentContextBeforeInput, !originContent.isEmpty else { return }
        
        do {
            var signatureKey: TCKey?
            if case .automatic = KeyboardPreference.kMessageDigitalSignatureSettings {
                signatureKey = ProfileService.default.defaultSignatureKey
            }
            
            guard let signKey = signatureKey else { return }
            
            let signedMessage = try KeyFactory.clearsignMessage(originContent, signatureKey: signKey)
            var message = Message(id: nil, senderKeyId: signatureKey?.longIdentifier ?? "", senderKeyUserId: signatureKey?.userID ?? "", composedAt: Date(), interpretedAt: nil, isDraft: false, rawMessage: originContent, encryptedMessage: signedMessage)
            try ProfileService.default.addMessage(&message, recipientKeys: [])

            keyboardVC?.textDocumentProxy.insertText(signedMessage)
            
            mode = .typing
        } catch {
            consolePrint(error.localizedDescription)
            toastAlerter.alert(message: error.localizedDescription, in: keyboardVC!.view)
        }
    }
}
