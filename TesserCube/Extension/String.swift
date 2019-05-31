//
//  String.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-3-26.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation

extension String {

    func separate(every stride: Int = 4, with separator: Character = " ") -> String {
        return String(enumerated().map { $0 > 0 && $0 % stride == 0 ? [separator, $1] : [$1]}.joined())
    }

}
