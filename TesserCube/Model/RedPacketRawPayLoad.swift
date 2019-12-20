//
//  RedPacketRawPayLoad.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-20.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import BigInt

public struct RedPacketRawPayLoad: Codable {
    let contract_version: UInt8
    let contract_address: String
    let rpid: String
    let passwords: [String]     // uuids
    let sender: Sender
    let is_random: Bool
    let total: String           // BigUInt
    let creation_time: UInt64   // Unix timestamp
    let duration: UInt64        // in seconds
}

extension RedPacketRawPayLoad {
    public struct Sender: Codable {
        let address: String
        let name: String
        let message: String
    }
}
