//
//  UIViewController+EmptyView.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/18.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit

extension UIViewController {
    func addEmptyStateView(_ emptyView: UIView) {
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { maker in
            maker.edges.equalTo(view)
        }
    }
}
