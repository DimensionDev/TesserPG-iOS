//
//  Decimal.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-17.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import DMS_HDWallet_Cocoa
import BigInt

extension Decimal {
    
    // Helper for convert decimal in wei to BigUInt
    private var decimalInWeiFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        formatter.minimumIntegerDigits = 1
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }
    
    public var wei: BigUInt? {
        let amountInWei = self * HDWallet.CoinType.ether.exponent
        
        guard let amountInWeiString = decimalInWeiFormatter.string(from: amountInWei as NSNumber),
        let wei = BigUInt(amountInWeiString) else {
            return nil
        }
        
        return wei
    }
    
}
