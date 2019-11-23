//
//  DynamicTableView.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-22.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class DynamicTableView: UITableView {
    
    override var intrinsicContentSize: CGSize {
        self.layoutIfNeeded()
        return contentSize
    }
    
    override var contentSize: CGSize {
        didSet{
            invalidateIntrinsicContentSize()
        }
    }
    
}
