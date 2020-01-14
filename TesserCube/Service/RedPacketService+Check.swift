//
//  RedPacketService+Check.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import Foundation
import RealmSwift
import RxSwift
import Web3
import BigInt
import DeepDiff

extension RedPacketService {
    
    static func checkAvailability(for redPacket: RedPacket) -> Single<RedPacketAvailability> {
        os_log("%{public}s[%{public}ld], %{public}s: check availability for red packet - %s ", ((#file as NSString).lastPathComponent), #line, #function, redPacket.red_packet_id ?? "nil")

        // Only for contract v1
        assert(redPacket.contract_version == 1)
        
        do {
            try checkNetwork(for: redPacket)
        } catch {
            return Single.error(error)
        }
        
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
                let claimed = dict["claimed"] as? BigUInt,
                let expired = dict["expired"] as? Bool else {
                    single(.error(Error.checkAvailabilityFail))
                    return
                }
                
                let availability = RedPacketAvailability(balance: balance,
                                                         total: Int(total),
                                                         claimed: Int(claimed),
                                                         expired: expired)
                single(.success(availability))
            }
            
            return Disposables.create { }
        }
    }
    
    // Shared Observable sequeue from Single<RedPacketAvailability>
    func checkAvailability(for redPacket: RedPacket) -> Observable<RedPacketAvailability> {
        let id = redPacket.id
        
        guard let observable = checkAvailabilityQueue[id] else {
            let single = RedPacketService.checkAvailability(for: redPacket)
            
            let shared = single.asObservable()
                .flatMapLatest { availability -> Observable<RedPacketAvailability> in
                    let realm: Realm
                    do {
                        realm = try RedPacketService.realm()
                    } catch {
                        return Single.error(Error.internal(error.localizedDescription)).asObservable()
                    }
                    guard let redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
                        return Single.error(Error.internal("cannot reslove red packet to check availablity")).asObservable()
                    }
                    
                    do {
                        switch redPacket.status {
                        case .normal, .incoming:
                            try realm.write {
                                // .empty > .expired
                                if availability.claimed == availability.total {
                                    redPacket.status = .empty
                                } else if availability.expired {
                                    redPacket.status = .expired
                                }
                            }
                        case .claimed:
                            try realm.write {
                                if availability.expired {
                                    redPacket.status = .expired
                                }
                            }
                        default:
                            break
                        }
                    } catch {
                        return Single.error(Error.internal(error.localizedDescription)).asObservable()
                    }
                    
                    return Single.just(availability).asObservable()
                }
                .share()
            
            checkAvailabilityQueue[id] = shared

            shared
                .asSingle()
                .do(afterSuccess: { _ in
                    os_log("%{public}s[%{public}ld], %{public}s: afterSuccess checkAvailability", ((#file as NSString).lastPathComponent), #line, #function)
                    self.checkAvailabilityQueue[id] = nil
                }, afterError: { _ in
                    os_log("%{public}s[%{public}ld], %{public}s: afterError checkAvailability", ((#file as NSString).lastPathComponent), #line, #function)
                    self.checkAvailabilityQueue[id] = nil
                })
                .subscribe()
                .disposed(by: disposeBag)
            
            return shared
        }
        
        os_log("%{public}s[%{public}ld], %{public}s: use checkAvailability in queue", ((#file as NSString).lastPathComponent), #line, #function)
        return observable
    }
    
}

extension RedPacketService {
    
    static func checkClaimedList(for redPacket: RedPacket) -> Single<[RedPacketClaimedRecord]> {
        os_log("%{public}s[%{public}ld], %{public}s: check claimed list for red packet - %s", ((#file as NSString).lastPathComponent), #line, #function, redPacket.red_packet_id ?? "nil")
        
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
            return Single.error(Error.internal("cannot get red packet id to check claimed list"))
        }
        
        guard let invocationFactory = contract["check_claimed_list"] else {
            return Single.error(Error.internal("cannot construct check_claimed_list invocation factory"))
        }
        
        let invocation = invocationFactory(redPacketID)
        
        return Single.create { single -> Disposable in
            invocation.call { resultDict, error in
                guard error == nil else {
                    single(.error(error!))
                    return
                }
                
                guard let dict = resultDict else {
                    single(.error(Error.internal("cannot read check claimed list result")))
                    return
                }
                
                guard let claimed_list = dict["claimed_list"] as? [BigUInt],
                let claimer_addrs = dict["claimer_addrs"] as? [EthereumAddress],
                claimed_list.count == claimer_addrs.count else {
                    single(.error(Error.checkAvailabilityFail))
                    return
                }
                
                os_log("%{public}s[%{public}ld], %{public}s: %s claimer(s)", ((#file as NSString).lastPathComponent), #line, #function, String(claimer_addrs.count))

                let records = zip(claimed_list, claimer_addrs).map { claimed, claimer in
                    return RedPacketClaimedRecord(claimed: claimed, claimer: claimer)
                }
                
                single(.success(records))
            }
            return Disposables.create { }
        }

    }
    
}

extension RedPacketService {
    
    struct RedPacketAvailability {
        let balance: BigUInt        // remains
        let total: Int              // total share count
        let claimed: Int            // claimed share count
        let expired: Bool           // is expired
    }
    
    struct RedPacketClaimedRecord {
        let claimed: BigUInt
        let claimer: EthereumAddress
    }
    
}

extension RedPacketService.RedPacketClaimedRecord: Hashable {
    
}

extension RedPacketService.RedPacketClaimedRecord: DiffAware {
    var diffId: Int {
        return hashValue
    }

    static func compareContent(_ a: RedPacketService.RedPacketClaimedRecord, _ b: RedPacketService.RedPacketClaimedRecord) -> Bool {
        return a.claimed == b.claimed && a.claimer == b.claimer
    }
}
