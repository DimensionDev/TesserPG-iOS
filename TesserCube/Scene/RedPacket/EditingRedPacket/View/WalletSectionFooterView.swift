//
//  WalletSectionFooterView.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-9.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

final class WalletSectionFooterView: UIView {
    
    let walletBalanceLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 12)
        label.textColor = ._secondaryLabel
        return label
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    private func _init() {
        walletBalanceLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(walletBalanceLabel)
        NSLayoutConstraint.activate([
            walletBalanceLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            walletBalanceLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: readableContentGuide.leadingAnchor, multiplier: 1.0),
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: walletBalanceLabel.trailingAnchor),
            bottomAnchor.constraint(equalTo: walletBalanceLabel.bottomAnchor, constant: 8),
        ])
    }
    
}
