//
//  UITableView.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-26.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

extension UITableView {
    
    public static func setupTopSectionSeparatorLine(for cell: UITableViewCell) {
        let tag = 3868

        if let oldSeparatorLine = cell.contentView.subviews.first(where: { $0.tag == tag }) {
            oldSeparatorLine.removeFromSuperview()
        }
        
        let separatorLine: UIView = {
            let separatorLine = UIView(frame: CGRect(x: 0, y: 0, width: cell.bounds.width, height: 0.5))
            separatorLine.tag = tag
            separatorLine.backgroundColor = ._separator
            return separatorLine
        }()
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            // not use contentView anchor here due to accessory view set padding for it
            separatorLine.topAnchor.constraint(equalTo: cell.topAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: cell.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }
    
    public static func setupBottomSectionSeparatorLine(for cell: UITableViewCell) {
        let tag = 3869

        if let oldSeparatorLine = cell.contentView.subviews.first(where: { $0.tag == tag }) {
            oldSeparatorLine.removeFromSuperview()
        }
        
        let separatorLine: UIView = {
            let separatorLine = UIView(frame: CGRect(x: 0, y: 0, width: cell.bounds.width, height: 0.5))
            separatorLine.tag = tag
            separatorLine.backgroundColor = ._separator
            return separatorLine
        }()
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            // not use contentView anchor here due to accessory view set padding for it
            separatorLine.leadingAnchor.constraint(equalTo: cell.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: cell.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }
    
}
