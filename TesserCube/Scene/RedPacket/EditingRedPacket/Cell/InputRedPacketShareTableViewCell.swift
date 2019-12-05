//
//  InputRedPacketShareTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-22.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class InputRedPacketShareTableViewCell: UITableViewCell, LeftDetailStyle {
        
    let disposeBag = DisposeBag()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    var detailLeadingLayoutConstraint: NSLayoutConstraint!
    
    let detailView: UIView = {
        let view = UIView()
        view.backgroundColor = ._secondarySystemGroupedBackground
        return view
    }()
    let shareLabel: UILabel = {
        let label = UILabel()
        label.text = "1"
        return label
    }()
    let shareStepper: UIStepper = {
        let stepper = UIStepper()
        stepper.minimumValue = 1
        stepper.maximumValue = 100
        stepper.stepValue = 1
        stepper.value = 1
        return stepper
    }()
    
    // Output
    let share = BehaviorRelay(value: 1)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    private func _init() {
        
        selectionStyle = .none
        contentView.backgroundColor = ._systemGroupedBackground
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        detailView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(detailView)
        detailLeadingLayoutConstraint = detailView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor)
        NSLayoutConstraint.activate([
            detailView.topAnchor.constraint(equalTo: contentView.topAnchor),
            detailLeadingLayoutConstraint,
            detailView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            detailView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        // Layout detail view
        shareLabel.translatesAutoresizingMaskIntoConstraints = false
        detailView.addSubview(shareLabel)
        NSLayoutConstraint.activate([
            shareLabel.topAnchor.constraint(equalToSystemSpacingBelow: detailView.topAnchor, multiplier: 1.0),
            shareLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: detailView.leadingAnchor, multiplier: 1.0),
            detailView.bottomAnchor.constraint(equalToSystemSpacingBelow: shareLabel.bottomAnchor, multiplier: 1.0),
        ])
        
        shareStepper.translatesAutoresizingMaskIntoConstraints = false
        detailView.addSubview(shareStepper)
        NSLayoutConstraint.activate([
            shareStepper.topAnchor.constraint(equalToSystemSpacingBelow: detailView.topAnchor, multiplier: 1.0),
            shareStepper.leadingAnchor.constraint(equalToSystemSpacingAfter: shareLabel.trailingAnchor, multiplier: 1.0),
            detailView.trailingAnchor.constraint(equalToSystemSpacingAfter: shareStepper.trailingAnchor, multiplier: 1.0),
            detailView.bottomAnchor.constraint(equalToSystemSpacingBelow: shareStepper.bottomAnchor, multiplier: 1.0),
        ])
        shareStepper.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        shareStepper.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        // FIXME:
        
        // Bind stepper target & action
        shareStepper.rx.value.asDriver()
            .map { Int($0) }
            .drive(share)
            .disposed(by: disposeBag)
        
        // Setup Stepper label
        share.asDriver()
            .map { String($0) }
            .drive(shareLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
}
