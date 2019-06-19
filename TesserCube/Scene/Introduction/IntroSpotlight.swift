//
//  IntroSpotlight.swift
//  TesserCube
//
//  Created by jk234ert on 2019/6/17.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

@objc
class IntroSpotlight: NSObject {
    enum IntroSpotlightShape {
        case rectangle
        case oval
        
        func getPath(rect: CGRect) -> UIBezierPath {
            switch self {
            case .rectangle:
                return UIBezierPath(rect: rect)
            case .oval:
                return UIBezierPath(ovalIn: rect)
            }
        }
    }
    
    var rect: CGRect
    var shape: IntroSpotlightShape
    var visiblePath: UIBezierPath
    
    init(rect: CGRect, shape: IntroSpotlightShape) {
        self.rect = rect
        self.shape = shape
        self.visiblePath = shape.getPath(rect: rect)
    }
}
