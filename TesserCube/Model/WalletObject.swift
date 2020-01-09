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
    
    public dynamic var balance: BigUInt? {
        get { _eth_balance.flatMap { BigUInt($0, radix: 10) } }
        set { _eth_balance = newValue.flatMap { String($0) } }
    }
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    override public class func ignoredProperties() -> [String] {
        return ["balance"]
    }
    
}
