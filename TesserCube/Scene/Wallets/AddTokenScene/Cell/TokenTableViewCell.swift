//
//  TokenTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-9.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class TokenTableViewCell: UITableViewCell {
    
    var disposeBag = DisposeBag()
    
    let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = ._systemFill
        imageView.layer.cornerRadius = 4
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    let symbolLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 17)
        label.textColor = ._label
        return label
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 15)
        label.textColor = ._secondaryLabel
        return label
    }()
    
    let balanceLabel: UILabel = {
        let label = UILabel()
        label.font = FontFamily.SFProText.regular.font(size: 17)
        label.textColor = ._label
        return label
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        logoImageView.image = nil
        symbolLabel.text = ""
        nameLabel.text = ""
        balanceLabel.text = ""
        
        disposeBag = DisposeBag()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension TokenTableViewCell {
    
    private func _init() {
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(logoImageView)
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            logoImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 10),
            logoImageView.heightAnchor.constraint(equalToConstant: 40),
            logoImageView.widthAnchor.constraint(equalToConstant: 40),
        ])
        
        symbolLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(symbolLabel)
        NSLayoutConstraint.activate([
            symbolLabel.topAnchor.constraint(equalTo: logoImageView.topAnchor),
            symbolLabel.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 16),
        ])
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: symbolLabel.bottomAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: symbolLabel.leadingAnchor),
        ])
        
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(balanceLabel)
        NSLayoutConstraint.activate([
            balanceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            balanceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: symbolLabel.trailingAnchor, constant: 8),
            balanceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 8),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: balanceLabel.trailingAnchor),
        ])
        balanceLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
    
}
