//
//  MessageSectionHeaderView.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-26.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

final class RedPacketMessageSectionHeaderView: UIView {
    
    let headerLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 13)
        label.textColor = ._secondaryLabel
        label.text = "Message"
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
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerLabel)
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            headerLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: readableContentGuide.leadingAnchor, multiplier: 1.0),
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: headerLabel.trailingAnchor),
            bottomAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
        ])
    }
    
}
