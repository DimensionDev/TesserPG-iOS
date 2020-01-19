//
//  RedPacket+V1.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-17.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation

extension RedPacket {
    
    static func v1(for network: EthereumNetwork) -> RedPacket {
        let redPacket = RedPacket()
        
        redPacket.aes_version = 1
        redPacket.contract_version = 1
        redPacket.contract_address = Web3Secret.contractAddressV1(for: network)
        redPacket.network = network
        
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
