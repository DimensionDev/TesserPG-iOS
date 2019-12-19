//
//  RedPacketService+RedPacket.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-18.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import Foundation
import RealmSwift
import RxSwift
import RxCocoa

extension RedPacketService {
    
    func updateCreateResult(for redPacket: RedPacket) -> Observable<CreationSuccess> {
        let observable = Observable.just(ThreadSafeReference(to: redPacket))
            .flatMap { redPacketReference -> Observable<RedPacketService.CreationSuccess> in
                let realm: Realm
                let redPacket: RedPacket
                
                do {
                    realm = try RedPacketService.realm()
                    guard let _redPacket = realm.resolve(redPacketReference) else {
                        return Observable.error(RedPacketService.Error.internal("cannot resolve red packet"))
                    }
                    redPacket = _redPacket
                } catch {
                    return Observable.error(error)
                }
                
                return RedPacketService.createResult(for: redPacket).asObservable()
                    .retry(3)   // network retry
            }
            .observeOn(MainScheduler.instance)
            .share()
        
        observable
            .subscribe(onNext: { creationSuccess in
                let realm: Realm
                let redPacketReference = ThreadSafeReference(to: redPacket)
                do {
                    realm = try RedPacketService.realm()
                    guard let redPacket = realm.resolve(redPacketReference) else {
                        return
                    }
                    
                    try realm.write {
                        redPacket.red_packet_id = creationSuccess.id
                        redPacket.block_creation_time.value = creationSuccess.creation_time
                        redPacket.status = .normal
                    }
                } catch {
                    os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                }
            }, onError: { error in
                switch error {
                case RedPacketService.Error.creationFail:
                    let realm: Realm
                    let redPacketReference = ThreadSafeReference(to: redPacket)
                    do {
                        realm = try RedPacketService.realm()
                        guard let redPacket = realm.resolve(redPacketReference) else {
                            return
                        }
                        
                        try realm.write {
                            redPacket.status = .fail
                        }
                    } catch {
                        os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    }
                default:
                    break
                }
            
            })
            .disposed(by: disposeBag)
        
        return observable
    }
    
}
