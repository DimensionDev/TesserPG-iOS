//
//  SeparatorView.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/3/4.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit

class SeparatorView: UIView, Thematic {
    
    static let separatorHeight: CGFloat = 20
    static let separatorWidth: CGFloat = 1
    
    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: SeparatorView.separatorWidth, height: SeparatorView.separatorHeight))
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
        let separator = UIView(frame: .zero)
        separator.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        addSubview(separator)
        separator.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(SeparatorView.separatorHeight)
            make.top.equalToSuperview().offset(14.5)
        }
        updateColor(theme: KeyboardModeManager.shared.currentTheme)
    }
    
    func updateColor(theme: Theme) {
        switch theme {
        case .light:
            subviews.forEach { $0.backgroundColor = UIColor.black.withAlphaComponent(0.1) }
        case .dark:
            subviews.forEach { $0.backgroundColor = UIColor.white.withAlphaComponent(0.1) }
        }
    }
}
