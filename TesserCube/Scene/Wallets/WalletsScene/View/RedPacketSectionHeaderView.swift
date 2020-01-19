//
//  RedPacketSectionHeaderView.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-18.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class RedPacketSectionHeaderView: UITableViewHeaderFooterView {
    
    var disposeBag = DisposeBag()
    
    let label: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 13)
        label.textColor = ._secondaryLabel
        label.text = "Red Packet History"
        
        return label
    }()
    let separatorLine: UIView = {
        let separatorLine = UIView()
        separatorLine.backgroundColor = ._separator
        return separatorLine
    }()
    let blurEffect: UIVisualEffect = {
        let effect: UIVisualEffect
        if #available(iOS 13.0, *) {
            effect = UIBlurEffect(style: .systemMaterial)
        } else {
            effect = UIBlurEffect(style: .light)
        }
        return effect
    }()
    let blurEffectBackgroundView: UIVisualEffectView = {
        return UIVisualEffectView(effect: nil)
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension RedPacketSectionHeaderView {
    
    private func _init() {
        backgroundColor = .clear
        backgroundView = blurEffectBackgroundView
        
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            label.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 5),
        ])
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
}
