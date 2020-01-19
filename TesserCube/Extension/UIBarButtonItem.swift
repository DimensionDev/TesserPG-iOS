//
//  UIBarButtonItem.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-9.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import UIKit

extension UIBarButtonItem {
    
    static var close: UIBarButtonItem {
        if #available(iOS 13.0, *) {
            return UIBarButtonItem(barButtonSystemItem: .close, target: nil, action: nil)
        } else {
            return UIBarButtonItem(barButtonSystemItem: .stop, target: nil, action: nil)
        }
    }
    
}
