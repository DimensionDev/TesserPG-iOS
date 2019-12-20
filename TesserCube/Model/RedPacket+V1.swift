//
//  RedPacket+V1.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-17.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation

extension RedPacket {
    
    static func v1() -> RedPacket {
        let redPacket = RedPacket()
        
        redPacket.aes_version = 1
        redPacket.contract_version = 1
        
        // RP:1d9ba33e6ff28f91ff94ef36c04b5837282c8ef0 on Rinkeby
        redPacket.contract_address = "0x65cb40bb219ea5962e0a9894449052568a62c823"
        
        assert(!redPacket.contract_address.isEmpty)
        
        return redPacket
    }
    
}
