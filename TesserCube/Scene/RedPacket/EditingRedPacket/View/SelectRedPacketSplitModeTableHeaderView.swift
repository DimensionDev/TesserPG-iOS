//
//  SelectRedPacketSplitModeTableHeaderView.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-22.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

final class SelectRedPacketSplitModeTableHeaderView: UIView {
    
    let modeSegmentedControl: UISegmentedControl = {
        let items = ["Average Mode", "Random Mode"]
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.selectedSegmentIndex = 0
        return segmentedControl
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    func _init() {
        modeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        addSubview(modeSegmentedControl)
        let bottomLayoutConstraint = bottomAnchor.constraint(equalTo: modeSegmentedControl.bottomAnchor)
        bottomLayoutConstraint.priority = .defaultHigh   // fix UIView-Encapsulated-Layout-Height conflict
        let trailingLayoutConstraint = layoutMarginsGuide.trailingAnchor.constraint(equalTo: modeSegmentedControl.trailingAnchor)
        trailingLayoutConstraint.priority = .defaultHigh // fix UIView-Encapsulated-Layout-Width conflict
        NSLayoutConstraint.activate([
            modeSegmentedControl.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            modeSegmentedControl.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            trailingLayoutConstraint,
            bottomLayoutConstraint,
        ])
    }

}
