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
        
        assert(!redPacket.contract_address.isEmpty)
        
        return redPacket
    }
    
}
