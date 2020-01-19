//
//  RedPacket.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-25.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import Foundation
import RealmSwift
import BigInt

public class RedPacket: Object {
    
    public typealias ID = String
    
    @objc public dynamic var id: ID = UUID().uuidString
    
    @objc public dynamic var aes_version = 1
    @objc public dynamic var contract_version = 1
    @objc public dynamic var contract_address: String = ""
    @objc private dynamic var _network = EthereumNetwork.rinkeby.rawValue

    let uuids = List<String>()
    @objc public dynamic var is_random = false

    let create_nonce = RealmOptional<Int>()
    @objc public dynamic var create_transaction_hash: String?
    let block_creation_time = RealmOptional<Int>(Int(Date().timeIntervalSince1970))
    @objc public dynamic var duration = 86400       // 24hr
    @objc public dynamic var red_packet_id: String?
    @objc public dynamic var raw_payload: String?
    @objc public dynamic var enc_payload: String?
    
    @objc public dynamic var sender_address = ""
    @objc public dynamic var sender_name = ""
    @objc private dynamic var _send_total = "0"
    @objc public dynamic var send_message = ""
    
    @objc public dynamic var last_share_time: Date?
    
    @objc public dynamic var claim_address: String?
    @objc public dynamic var claim_transaction_hash: String?
    @objc private dynamic var _claim_amount = "0"
    
    @objc public dynamic var refund_transaction_hash: String?
    @objc private dynamic var _refund_amount = "0"
    
    @objc private dynamic var _status = RedPacketStatus.initial.rawValue
    
    @objc private dynamic var _token_type = RedPacketTokenType.eth.rawValue
    @objc public dynamic var erc20_token: ERC20Token?
    let erc20_approve_transaction_nonce = RealmOptional<Int>()
    @objc public dynamic var erc20_approve_transaction_hash: String?
    @objc private dynamic var _erc20_approve_value: String?
    
    @objc public dynamic var received_time: Date?
    
    public dynamic var network: EthereumNetwork {
        get { return EthereumNetwork(rawValue: _network) ?? .rinkeby }
        set { _network = newValue.rawValue }
    }
        
    public dynamic var send_total: BigUInt {
        get { return BigUInt(_send_total, radix: 10)! }
        set { _send_total = String(newValue) }
    }
    public dynamic var claim_amount: BigUInt {
        get { return BigUInt(_claim_amount, radix: 10)! }
        set { _claim_amount = String(newValue) }
    }
    public dynamic var refund_amount: BigUInt {
        get { return BigUInt(_refund_amount, radix: 10)! }
        set { _refund_amount = String(newValue) }
    }
    public dynamic var status: RedPacketStatus {
        get { return RedPacketStatus(rawValue: _status) ?? .initial }
        set { _status = newValue.rawValue }
    }
    public dynamic var token_type: RedPacketTokenType {
        get { return RedPacketTokenType(rawValue: _token_type) ?? .eth }
        set { _token_type = newValue.rawValue }
    }
    public dynamic var erc20_approve_value: BigUInt? {
        get { return _erc20_approve_value.flatMap { BigUInt($0, radix: 10)! } }
        set { _erc20_approve_value = newValue.flatMap { String($0) } }
    }
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    override public class func ignoredProperties() -> [String] {
        return ["network", "send_total", "claim_amount", "refund_amount", "token_type", "erc20_approve_value"]
    }
}

public enum RedPacketStatus: String {
    case initial    // ready to send
    case pending    // sent but pending
    case fail       // fail to send
    case incoming   // recieved red packet
    case normal
    case claim_pending
    case claimed
    case expired
    case empty      // all claimed
    case refund_pending
    case refunded
}

public enum RedPacketTokenType: String, Codable {
    case eth
    case erc20
    
    public var contractParameter: BigUInt {
        switch self {
        case .eth:      return BigUInt(0)
        case .erc20:    return BigUInt(1)
        }
    }
}

public enum EthereumNetwork: String, Codable {
    case mainnet = "Mainnet"
    case rinkeby = "Rinkeby"
    case ropsten = "Ropsten"
}
