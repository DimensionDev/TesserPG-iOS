//
//  UITableView.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-26.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

extension UITableView {
    
    private static let topSectionTag = 3868
    private static let bottomSectionTag = 3869
    private static let bottomCellTag = 3870
    

    public static func removeSectionSeparatorLine(for cell: UITableViewCell) {
        if let oldSeparatorLine = cell.contentView.subviews.first(where: { $0.tag == topSectionTag }) {
            oldSeparatorLine.removeFromSuperview()
        }
        
        if let oldSeparatorLine = cell.contentView.subviews.first(where: { $0.tag == bottomSectionTag }) {
            oldSeparatorLine.removeFromSuperview()
        }
        
        if let oldSeparatorLine = cell.contentView.subviews.first(where: { $0.tag == bottomCellTag }) {
            oldSeparatorLine.removeFromSuperview()
        }
    }
    
    public static func setupTopSectionSeparatorLine(for cell: UITableViewCell) {
        let tag = topSectionTag

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
        let tag = bottomSectionTag

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
    
    public static func setupBottomCellSeparatorLine(for cell: UITableViewCell) {
        let tag = bottomCellTag
        
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
            separatorLine.leadingAnchor.constraint(equalTo: cell.layoutMarginsGuide.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }
    
}
