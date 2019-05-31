//
//  InterpretFailView.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/4/5.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit

protocol InterpretFailViewDelegate: class {
    func interpretFailView(_ view: InterpretFailView, didClickedClose button: UIButton)
}

class InterpretFailView: UIView, Thematic {
    
    weak var delegate: InterpretFailViewDelegate?
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = .white
        label.font = FontFamily.SFProDisplay.medium.font(size: 16)
        label.text = L10n.Keyboard.Interpreted.Title.noNeccessaryPrivateKey
        return label
    }()
    
    private lazy var contentLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = .white
        label.font = FontFamily.SFProDisplay.regular.font(size: 16)
        label.text = L10n.Keyboard.Interpreted.Content.noNeccessaryPrivateKey
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setImage(Asset.buttonInterpretedCloseWhite.image, for: .normal)
        return button
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
        backgroundColor = UIColor(hex: 0xF20000)!
        addSubview(titleLabel)
        addSubview(contentLabel)
        addSubview(closeButton)
        
        closeButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(7)
            maker.trailing.equalToSuperview().offset(-7)
            maker.size.equalTo(CGSize(width: 28, height: 28))
        }
        
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(11)
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalTo(closeButton.snp.leading).offset(-16)
        }
        
        contentLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.leading)
            maker.top.equalTo(titleLabel.snp.bottom).offset(11)
            maker.trailing.equalToSuperview().offset(-16)
        }
        
        closeButton.addTarget(self, action: #selector(closeButtonDidClicked(_:)), for: .touchUpInside)
    }
    
    @objc
    private func closeButtonDidClicked(_ sender: UIButton) {
        delegate?.interpretFailView(self, didClickedClose: sender)
    }
    
    func updateColor(theme: Theme) {
        
    }
}
