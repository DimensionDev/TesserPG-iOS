//
//  WalletObject.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-9.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import Foundation
import RealmSwift
import BigInt

final class WalletObject: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var address = ""
    @objc dynamic var name = ""
    @objc dynamic var _eth_balance: String?
    @objc dynamic var _eth_ropsten_balance: String?
    @objc dynamic var _eth_rinkeby_balance: String?
        
    public dynamic var balance: BigUInt? {
        get { _eth_balance.flatMap { BigUInt($0, radix: 10) } }
        set { _eth_balance = newValue.flatMap { String($0) } }
    }
    
    public dynamic var ropsten_balance: BigUInt? {
        get { _eth_ropsten_balance.flatMap { BigUInt($0, radix: 10) } }
        set { _eth_ropsten_balance = newValue.flatMap { String($0) } }
    }
    
    public dynamic var rinkeby_balance: BigUInt? {
        get { _eth_rinkeby_balance.flatMap { BigUInt($0, radix: 10) } }
        set { _eth_rinkeby_balance = newValue.flatMap { String($0) } }
    }
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    override public class func ignoredProperties() -> [String] {
        return ["balance", "ropsten_balance", "rinkeby_balance"]
    }
    
}
