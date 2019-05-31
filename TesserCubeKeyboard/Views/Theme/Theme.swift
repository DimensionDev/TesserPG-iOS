//
//  Theme.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/2/21.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

enum Theme {
    case light
    case dark
}

protocol Thematic: class {
    
    func updateColor(theme: Theme)
}
