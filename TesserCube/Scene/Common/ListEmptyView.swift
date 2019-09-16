//
//  ListEmptyView.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/27.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit

class ListEmptyView: UIView {
    
    lazy var textLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = FontFamily.SFProDisplay.regular.font(size: 17)
        label.textColor = ._tertiaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    convenience init(title: String) {
        self.init(frame: .zero)
        textLabel.text = title
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configUI()
    }
    
    private func configUI() {
        addSubview(textLabel)
        textLabel.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        isUserInteractionEnabled = false
    }
}
