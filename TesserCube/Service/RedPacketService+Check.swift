//
//  RedPacketService+Check.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import Foundation
import RxSwift
import Web3
import BigInt

extension RedPacketService {
    
    static func checkAvailability(for redPacket: RedPacket) -> Single<RedPacketAvailability> {
        os_log("%{public}s[%{public}ld], %{public}s: check availability for red packet - %s ", ((#file as NSString).lastPathComponent), #line, #function, redPacket.red_packet_id ?? "nil")

        // Only for contract v1
        assert(redPacket.contract_version == 1)
        
        // Init web3
        let web3 = WalletService.web3
        
        // Init contract
        let contract: DynamicContract
        do {
            contract = try prepareContract(for: redPacket.contract_address, in: web3)
        } catch {
            return Single.error(Error.internal(error.localizedDescription))
        }
        
        // Prepare invocation
        guard let redPacketIDString = redPacket.red_packet_id,
        let redPacketID = BigUInt(hexString: redPacketIDString) else {
            return Single.error(Error.internal("cannot get red packet id to check availability"))
        }
        
        guard let invocationFactory = contract["check_availability"] else {
            return Single.error(Error.internal("cannot construct check_availability invocation factory"))
        }
        
        let invocation = invocationFactory(redPacketID)
        
        return Single.create { single -> Disposable in
            invocation.call { resultDict, error in
                guard error == nil else {
                    single(.error(error!))
                    return
                }
                
                guard let dict = resultDict else {
                    single(.error(Error.internal("cannot read check availability result")))
                    return
                }
                
                guard let balance = dict["balance"] as? BigUInt,
                let total = dict["total"] as? BigUInt,
                let claimed = dict["claimed"] as? BigUInt else {
                    single(.error(Error.checkAvailabilityFail))
                    return
                }
                
                let availability = RedPacketAvailability(balance: balance,
                                                         total: Int(total),
                                                         claimed: Int(claimed))
                single(.success(availability))
            }
            
            return Disposables.create { }
        }
    }
    
}

extension RedPacketService {
    
    struct RedPacketAvailability {
        let balance: BigUInt
        let total: Int
        let claimed: Int
    }
    
}
