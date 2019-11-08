//
//  RedPacketProperty.swift
//  TesserCube
//
//  Created by jk234ert on 11/6/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation

class RedPacketProperty {
    
    enum SplitType: Int, CaseIterable {
        case average
        case random
        
        var title: String {
            switch self {
            case .average:
                return "Average"
            case .random:
                return "Random"
            }
        }
    }
    
    var amount: Int = 0
    var splitType: SplitType = .average
    
    var sharesCount: Int = 1
    var wallet: TestWallet?
}
