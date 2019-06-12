//
//  UILabel.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-6-3.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

extension UILabel {
    var maxNumberOfLines: Int {
        assert(font != nil)
        let maxSize = CGSize(width: bounds.size.width, height: .greatestFiniteMagnitude)
        let text = (self.text ?? "") as NSString
        let textHeight = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [.font: font!], context: nil).height
        let lineHeight = font.lineHeight
        return Int(ceil(textHeight / lineHeight))
    }
}
