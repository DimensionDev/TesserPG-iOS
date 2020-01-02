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
        redPacket.contract_address = Web3Secret.contractAddressV1
        #if MAINNET
        redPacket.network = .mainnet
        #else
        redPacket.network = .rinkeby
        #endif
        
        #if DEBUG
        redPacket.duration = 86400         // 24h
        // redPacket.duration = 7200       // 2h
        // redPacket.duration = 60         // 1min
        #else
        redPacket.duration = 86400      // 24h
        #endif
        
        assert(!redPacket.contract_address.isEmpty)
        
        return redPacket
    }
    
}
