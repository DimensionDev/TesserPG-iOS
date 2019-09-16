//
//  SelectedRecipientView.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/2/21.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit

protocol SelectedRecipientViewDelegate: class {
    func selectedRecipientView(_ view: SelectedRecipientView, didClick contactInfo: FullContactInfo)
}

class SelectedRecipientView: UIView, Thematic {
    
    var contactInfos = [FullContactInfo]()
    
    weak var delegate: SelectedRecipientViewDelegate?
    
    private var recipientsScrollView: UIScrollView?
    private var stackView: UIStackView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configUI()
    }
    
    private func configUI() {
        createScrollView()
        createStackView()
        
        recipientsScrollView?.addSubview(stackView!)
        addSubview(recipientsScrollView!)
        
        setupConstraints()
    }
    
    private func createScrollView() {
        recipientsScrollView = UIScrollView(frame: .zero)
        recipientsScrollView?.showsHorizontalScrollIndicator = false
        recipientsScrollView?.alwaysBounceHorizontal = true
    }
    
    private func createStackView() {
        stackView = UIStackView(frame: .zero)
        stackView?.alignment = .bottom
        stackView?.axis = .horizontal
        stackView?.distribution = .equalSpacing
        stackView?.spacing = 5
    }
    
    private func setupConstraints() {
        
        recipientsScrollView?.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.top.bottom.equalToSuperview().offset(-1)
            make.trailing.equalToSuperview().offset(-5)
        }
        
        stackView?.snp.makeConstraints { make in
            make.leading.top.trailing.bottom.equalToSuperview()
            make.height.equalToSuperview()
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
    
    @objc
    private func recipientButtonDidClicked(_ sender: UIButton) {
        guard let index = stackView!.arrangedSubviews.firstIndex(where: { (subview) -> Bool in
            return subview == sender
        }) else { return }
        let toRemoveContactInfo = contactInfos[index]
        removeContactInfo(toRemoveContactInfo)
        delegate?.selectedRecipientView(self, didClick: toRemoveContactInfo)
    }
}

//MARK: Logic methods
extension SelectedRecipientView {
    
    func addContactInfo(_ contactInfo: FullContactInfo) {
        guard !contactInfos.contains(where: { (data) -> Bool in
            return data.contact.id == contactInfo.contact.id
        }) else {
            return
        }
        contactInfos.append(contactInfo)
        let recipientButton = RecipientButton(type: .custom)
        recipientButton.setTitle(contactInfo.contact.name, for: .normal)
        recipientButton.sizeToFit()
        recipientButton.addTarget(self, action: #selector(recipientButtonDidClicked(_:)), for: .touchUpInside)
        
        if let _ = stackView?.arrangedSubviews.last as? RecipientInputView {
            stackView?.insertArrangedSubview(recipientButton, at: stackView!.arrangedSubviews.count - 1)
        } else {
            stackView?.addArrangedSubview(recipientButton)
        }
        recipientButton.snp.makeConstraints { make in
            make.height.equalTo(32)
        }
        layoutIfNeeded()

        if contactInfos.count > 1 {
            // When appending 1st subview, following method would make scrollview scroll to unexpected area due to layout time racing
            recipientsScrollView?.scrollRectToVisible(recipientButton.frame, animated: true)
        }
    }
    
    func removeContactInfo(_ contactInfo: FullContactInfo) {
        guard let index = contactInfos.firstIndex(where: { (data) -> Bool in
            return data.contact.id == contactInfo.contact.id
        }) else { return }
        contactInfos.remove(at: index)
        let button = stackView?.arrangedSubviews[index]
        stackView?.removeArrangedSubview(button!)
        button?.removeFromSuperview()
        let offset = recipientsScrollView!.contentOffset.x
        let contentWidth = recipientsScrollView!.contentSize.width
        if contentWidth < offset {
            recipientsScrollView?.setContentOffset(CGPoint(x: recipientsScrollView!.contentSize.width - recipientsScrollView!.bounds.size.width, y: 0), animated: true)
        }
        
    }
    
    func removeAllContactInfos() {
        contactInfos.removeAll()
        stackView?.arrangedSubviews.forEach {
            stackView?.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        recipientsScrollView?.setContentOffset(.zero, animated: false)
    }
}
