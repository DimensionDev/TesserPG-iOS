//
//  IntroArrow.swift
//  TesserCube
//
//  Created by jk234ert on 2019/6/17.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

@objc
class IntroArrow: NSObject {
    enum ArrowDirection {
        case toTopRight
        case toBottomLeft
        case toBottomRight
        
        var image: UIImage {
            switch self {
            case .toTopRight:
                return Asset.introArrowTopRight.image
            case .toBottomLeft:
                return Asset.introArrowBottomLeft.image
            case .toBottomRight:
                return Asset.introArrowBottomRight.image
            }
        }
    }
    
    var direction: ArrowDirection
    var rect: CGRect
    
    init(direction: ArrowDirection, frame: CGRect) {
        self.direction = direction
        self.rect = frame
    }
}
