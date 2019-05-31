//
//  UIViewController+Alert.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/24.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

extension UIViewController {
    func showSimpleAlert(title: String? = nil, message: String? = nil) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: L10n.Common.Button.ok, style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alertVC, animated: true)
        }
    }
}
