//
//  RedPacketProperty.swift
//  TesserCube
//
//  Created by jk234ert on 11/6/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import BigInt
import DMS_HDWallet_Cocoa

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
    
    var walletModel: WalletModel?
    var amount: Decimal = 0
    var splitType: SplitType = .average
    var shareCount: Int = 1
    var sender: TCKey?
    
    // selected red packet recipients
    var contactInfos: [FullContactInfo] = [] {
        didSet {
            uuids = contactInfos.map { _ in UUID().uuidString }
        }
    }
    private(set) var uuids: [String] = []
}

extension RedPacketProperty {
    
    var amountInWei: BigUInt {
        let wei = HDWallet.CoinType.ether.exponent * amount
        let weiInString: String = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumIntegerDigits = 1
            formatter.groupingSeparator = ""
            
            return formatter.string(from: wei as NSNumber)!
        }()
        return BigUInt(weiInString)!
    }
    
}
