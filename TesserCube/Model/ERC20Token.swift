//
//  ERC20Token.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-8.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import Foundation
import RealmSwift

public class ERC20Token: Object {
    
    public typealias ID = String
    
    @objc public dynamic var id: ID = ""
    @objc public dynamic var address: String = ""
    @objc public dynamic var name: String = ""
    @objc public dynamic var symbol: String = ""
    @objc public dynamic var decimals: Int = 0
    @objc public dynamic var _network = EthereumNetwork.mainnet.rawValue
    @objc public dynamic var is_user_defind = true
    @objc public dynamic var deleted_at: Date?
    
    public dynamic var network: EthereumNetwork {
        get { return EthereumNetwork(rawValue: _network) ?? .mainnet }
        set { _network = newValue.rawValue }
    }
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    override public class func ignoredProperties() -> [String] {
        return ["network"]
    }
    
}
