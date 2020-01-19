//
//  RealOnlyTextField.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-10.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import UIKit

final class ReadOnlyTextField: UITextField {
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard action != #selector(cut(_:)) else {
            return false
        }
        
        guard action != #selector(delete(_:)) else {
            return false
        }
        
        guard action != #selector(paste(_:)) else {
            return false
        }
        
        guard action != Selector("_promptForReplace:") else {
            return false
        }
        
        return super.canPerformAction(action, withSender: sender)
    }
    
}
