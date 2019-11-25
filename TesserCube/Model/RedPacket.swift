//
//  RedPacket.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-25.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import RealmSwift
import BigInt

@objcMembers public class RedPacket: Object {
    @objc public dynamic var id = UUID().uuidString
    @objc public dynamic var createdAt = NSDate()

    @objc public dynamic var senderUserID: String = ""
    @objc public dynamic var share: Int = 1
    
    @objc private dynamic var _amount = "0"
    @objc private dynamic var _claimAmount = "0"
    @objc private dynamic var _status = RedPacketStatus.initial.rawValue
    
    @objc public dynamic var createContractTransactionHash: String? = nil
    @objc public dynamic var contractAddress: String? = nil
        

    public dynamic var amount: BigUInt {
        get { return BigUInt(_amount)! }
        set { _amount = String(newValue) }
    }
    public dynamic var claimAmount: BigUInt {
        get { return BigUInt(_claimAmount)! }
        set { _claimAmount = String(newValue) }
    }
    public dynamic var status: RedPacketStatus {
        get { return RedPacketStatus(rawValue: _status) ?? .initial }
        set { _status = newValue.rawValue }
    }
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    override public class func ignoredProperties() -> [String] {
        return ["amount", "claimAmount"]
    }
}

public enum RedPacketStatus: String {
    case initial    // ready to send
    case pending    // sent but pending
    case fail       // fail to send
    case incoming   // recieved red packet
    case normal
    case claimed
    case expired
}
