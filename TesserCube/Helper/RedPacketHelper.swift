//
//  RedPacketHelper.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-13.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import Foundation
import BigInt

struct RedPacketHelper {
    
    let tokenType: RedPacketTokenType
    
    let symbol: String
    let decimals: Int
    let exponent: Decimal
    
    let formatter: NumberFormatter
    
    let sendAmountInBigUInt: BigUInt
    let sendAmountInDecimal: Decimal?
    let sendAmountInDecimalString: String?
    
    let claimAmountInBigUInt: BigUInt
    let claimAmountInDecimal: Decimal?
    let claimAmountInDecimalString: String?
    
    let refundAmountInBigUInt: BigUInt
    let refundAmountInDecimal: Decimal?
    let refundAmountInDecimalString: String?
    
    init(for redPacket: RedPacket) {
        self.tokenType = redPacket.token_type
        self.symbol = redPacket.erc20_token?.symbol ?? "ETH"
        let _decimals = redPacket.erc20_token?.decimals ?? 18
        self.decimals = _decimals
        let _exponent = pow(10, redPacket.erc20_token?.decimals ?? 18)
        self.exponent = _exponent
        
        let _formatter: NumberFormatter = {
            switch redPacket.token_type {
            case .eth:
                return NumberFormatter.decimalFormatterForETH
            case .erc20:
                return NumberFormatter.decimalFormatterForToken(decimals: _decimals)
            }
        }()
        self.formatter = _formatter
        
        self.sendAmountInBigUInt = redPacket.send_total
        let _sendAmountInDecimal = (Decimal(string: String(redPacket.send_total)) ?? Decimal(0)) / _exponent
        self.sendAmountInDecimal = _sendAmountInDecimal
        self.sendAmountInDecimalString = _formatter.string(from: _sendAmountInDecimal as NSNumber)
        
        self.claimAmountInBigUInt = redPacket.claim_amount
        let _claimAmountInDecimal = (Decimal(string: String(redPacket.claim_amount)) ?? Decimal(0)) / _exponent
        self.claimAmountInDecimal = _claimAmountInDecimal
        self.claimAmountInDecimalString = _formatter.string(from: _claimAmountInDecimal as NSNumber)
        
        self.refundAmountInBigUInt = redPacket.refund_amount
        let _refundAmountInDecimal = (Decimal(string: String(redPacket.refund_amount)) ?? Decimal(0)) / _exponent
        self.refundAmountInDecimal = _refundAmountInDecimal
        self.refundAmountInDecimalString = _formatter.string(from: _refundAmountInDecimal as NSNumber)
    }

}
