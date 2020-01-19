//
//  WalletToken.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-9.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import Foundation
import RealmSwift
import BigInt

final class WalletToken: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var wallet: WalletObject?
    @objc dynamic var token: ERC20Token?
    @objc dynamic var index = 0
    @objc dynamic var _token_balance: String?
    
    public dynamic var balance: BigUInt? {
        get { _token_balance.flatMap { BigUInt($0, radix: 10) } }
        set { _token_balance = newValue.flatMap { String($0) } }
    }
 
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    override public class func ignoredProperties() -> [String] {
        return ["balance"]
    }
}
