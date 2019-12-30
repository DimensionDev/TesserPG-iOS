//
//  RedPacketValue.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-30.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation

// Struct wrapper for RedPacket object to handle value-type drive framework like diffable data source
public struct RedPacketValue {
    
    public let id: String
    public let redPacket: RedPacket
    public let status: RedPacketStatus
    
    init(redPacket: RedPacket) {
        self.id = redPacket.id
        self.redPacket = redPacket
        self.status = redPacket.status
    }
}

extension RedPacketValue: Equatable {
    
    public static func == (lhs: RedPacketValue, rhs: RedPacketValue) -> Bool {
        // For now we just compare id and status then return Realm isEqual (https://stackoverflow.com/questions/38868686/testing-for-equality-in-realm/38877533#38877533)
        // And RedPacket object is always same when its point to same thing
        return lhs.id == rhs.id &&
               lhs.status == rhs.status &&
               lhs.redPacket == rhs.redPacket
    }
    
}

extension RedPacketValue: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}
