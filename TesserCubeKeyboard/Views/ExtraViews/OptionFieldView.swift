//
//  OptionFieldView.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/3/4.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit

class OptionFieldView: UIView {
    
    var actionsView: ActionsView!
    var suggestionView: SuggestionView?
    var selectedRecipientsView: SelectedRecipientView?
    
    var selectedContacts: [FullContactInfo] {
        get {
            return selectedRecipientsView?.contactInfos ?? []
        }
    }
    
    private lazy var fullAccessHintView: FullAccessHintView = {
        let view = FullAccessHintView(frame: .zero)
        view.backgroundColor = UIColor(hex: 0xD1D3D9)!
//        let hintLabel = UILabel(frame: .zero)
//        hintLabel.textAlignment = .center
//        hintLabel.text = L10n.Keyboard.Prompt.enableFullAccess
//        hintLabel.numberOfLines = 2
//        hintLabel.font = FontFamily.SFProDisplay.regular.font(size: 16)
//        hintLabel.textColor = .darkGray
//        view.addSubview(hintLabel)
//        hintLabel.snp.makeConstraints({ maker in
//            maker.leading.equalToSuperview().offset(16)
//            maker.trailing.equalToSuperview().offset(-16)
//            maker.top.equalToSuperview().offset(6)
//            maker.bottom.equalToSuperview()
//        })
        view.isHidden = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configUI()
    }
    
    private func configUI() {
        createActionView()
        createSuggestionView()
        createSelectedRecipientsView()
        setupFullAcessHintView()
        setupConstraints()
    }
    
    private func createActionView() {
        actionsView = ActionsView(actions: [.modeChange])
        addSubview(actionsView)
    }
    
    private func createSuggestionView() {
        suggestionView = SuggestionView(frame: .zero)
        addSubview(suggestionView!)
    }
    
    private func createSelectedRecipientsView() {
        selectedRecipientsView = SelectedRecipientView(frame: .zero)
        addSubview(selectedRecipientsView!)
        selectedRecipientsView?.isHidden = true
    }
    
    private func setupConstraints() {
        actionsView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.trailing.equalToSuperview()
        }

        suggestionView?.snp.makeConstraints{ make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.equalTo(actionsView.snp.leading)
        }

        selectedRecipientsView?.snp.makeConstraints{ make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.equalTo(actionsView.snp.leading)
        }
    }
//
//    func updateColor(theme: Theme) {
//        switch theme {
//        case .light:
//            fullAccessHintView.backgroundColor = UIColor(hex: 0xD1D3D9)!
//            break
//        case .dark:
//            fullAccessHintView.backgroundColor = Asset.keyboardBackgroundDark.color
//        }
//    }
    
    private func setupFullAcessHintView() {
        addSubview(fullAccessHintView)
        fullAccessHintView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-61)
        }
        
        fullAccessHintView.isUserInteractionEnabled = true
        fullAccessHintView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(fullAccessHintViewDidTapped(_:))))
        
    }
    
    func setFullAccessHintViewVisible(_ visible: Bool) {
        fullAccessHintView.isHidden = !visible
        
    }
    
    
    
    @objc
    private func fullAccessHintViewDidTapped(_ sender: UITapGestureRecognizer) {
        #if TARGET_IS_EXTENSION
        UIApplication.sharedApplication().openContainerAppForFullAccess()
        #endif
    }
}

#if TARGET_IS_EXTENSION
extension OptionFieldView {
    
    func updateLayout(mode: KeyboardMode) {
        // always show action title
        let noRecipients = selectedRecipientsView?.contactInfos.isEmpty ?? true;
        actionsView.setButtonsTitleVisible(noRecipients)
        
    }

}

// MARK: - KeyboardModeListener
extension OptionFieldView: KeyboardModeListener {
    
    func update(mode: KeyboardMode) {
        switch mode {
        case .typing:
            actionsView.actions = mode.actions
            actionsView.resetButtonStatus()
            //            updateLayout(mode: mode)
            suggestionView?.isHidden = false
            selectedRecipientsView?.isHidden = true
        case .editingRecipients:
            actionsView.actions = mode.actions
            actionsView.modeChangeButton?.isSelected = true
            suggestionView?.isHidden = true
            selectedRecipientsView?.isHidden = false
        default:
            break
        }
        updateLayout(mode: mode)
    }

}
#endif

extension OptionFieldView {
    func addSelectedRecipient(_ contactInfo: FullContactInfo) {
        selectedRecipientsView?.addContactInfo(contactInfo)
        #if TARGET_IS_EXTENSION
        updateLayout(mode: KeyboardModeManager.shared.mode)
        #endif
    }
    
    func removeSelectedRecipient(_ contactInfo: FullContactInfo) {
        selectedRecipientsView?.removeContactInfo(contactInfo)
        #if TARGET_IS_EXTENSION
        updateLayout(mode: KeyboardModeManager.shared.mode)
        #endif
    }
    
    func removeAllSelectedRecipients() {
        selectedRecipientsView?.removeAllContactInfos()
        #if TARGET_IS_EXTENSION
        updateLayout(mode: KeyboardModeManager.shared.mode)
        #endif
    }
}
