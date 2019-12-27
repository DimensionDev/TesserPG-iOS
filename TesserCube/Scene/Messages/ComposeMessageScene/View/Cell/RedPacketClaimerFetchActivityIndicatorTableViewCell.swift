//
//  RedPacketClaimerFetchActivityIndicatorTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-27.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

final class RedPacketClaimerFetchActivityIndicatorTableViewCell: UITableViewCell {
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            activityIndicatorView = UIActivityIndicatorView(style: .medium)
        } else {
            activityIndicatorView = UIActivityIndicatorView(style: .gray)
        }
        activityIndicatorView.startAnimating()
        return activityIndicatorView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension RedPacketClaimerFetchActivityIndicatorTableViewCell {
    
    private func _init() {
        selectionStyle = .none
     
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
    }
    
}
