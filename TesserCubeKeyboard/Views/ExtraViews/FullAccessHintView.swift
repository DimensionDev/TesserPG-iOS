//
//  FullAccessHintView.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/4/16.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class FullAccessHintView: UIView, Thematic {
    
    private let hintLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.text = L10n.Keyboard.Prompt.enableFullAccess
        label.numberOfLines = 2
        label.font = FontFamily.SFProDisplay.regular.font(size: 16)
        label.textColor = .darkGray
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configUI() {
        backgroundColor = UIColor(hex: 0xD1D3D9)!
        
        addSubview(hintLabel)
        hintLabel.snp.makeConstraints({ maker in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(6)
            maker.bottom.equalToSuperview()
        })
//        isHidden = true
    }
    
    func updateColor(theme: Theme) {
        switch theme {
        case .light:
            hintLabel.textColor = .darkGray
            backgroundColor = .keyboardBackgroundLight
        case .dark:
            hintLabel.textColor = .white
            backgroundColor = .keyboardBackgroundDark
        }
    }
}

