//
//  NumberFormatter.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-17.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation

extension NumberFormatter {
    
    static var decimalFormatterForETH: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumIntegerDigits = 1
        formatter.maximumFractionDigits = 9 // percision to 1gwei
        formatter.groupingSeparator = ""
        return formatter
    }
    
}
