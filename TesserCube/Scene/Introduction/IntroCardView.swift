//
//  IntroCardView.swift
//  TesserCube
//
//  Created by jk234ert on 2019/6/17.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit

class IntroCardView: UIView {
    
    private let paraghStyle: NSParagraphStyle = {
        var style = NSMutableParagraphStyle()
        style.lineSpacing = 0
        style.minimumLineHeight = 26
        style.alignment = .center
        return style
    }()
    
    var guideLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        return label
    }()
    
    var cardView: TCCardView = {
        let cardView = TCCardView()
        cardView.cardBackgroundColor = Asset.sketchBlue.color
        return cardView
    }()
    
    var nextButton: TCActionButton = {
        let button = TCActionButton(frame: .zero)
        button.minHeight = 40
        button.color = .white
        button.setTitleColor(.black, for: .normal)
        button.setTitle(L10n.WizardViewController.Action.Button.next, for: .normal)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .clear
        setupSubViews()
    }
    
    private func setupSubViews() {
        addSubview(cardView)
        addSubview(guideLabel)
        addSubview(nextButton)
        
        cardView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        
        guideLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(14)
            maker.trailing.equalToSuperview().offset(-14)
            maker.top.equalToSuperview().offset(20)
        }
        
        nextButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(72)
            maker.trailing.equalToSuperview().offset(-72)
            maker.top.equalTo(guideLabel.snp.lastBaseline).offset(20)
            maker.bottom.equalToSuperview().offset(-20)
        }
    }
    
    func setGuideText(_ guideText: String) {
        guideLabel.attributedText = NSAttributedString(string: guideText, attributes:
            [NSAttributedString.Key.font: FontFamily.SFProDisplay.regular.font(size: 20)!,
             NSAttributedString.Key.foregroundColor: UIColor.white,
             NSAttributedString.Key.paragraphStyle: paraghStyle
            ])
    }
    
    func setLastStepStyle() {
        cardView.snp.remakeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.bottom.equalTo(guideLabel.snp.bottom).offset(20)
        }
        nextButton.isHidden = true
    }
}
