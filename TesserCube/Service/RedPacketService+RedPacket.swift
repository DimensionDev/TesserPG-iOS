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
        // should call on main thread to make sure realm operation in subscribe is thread safe
        assert(Thread.isMainThread)
        let id = redPacket.id
        
        let observable = Observable.just(id)
            .flatMap { id -> Observable<RedPacketService.CreationSuccess> in
                let redPacket: RedPacket
                do {
                    let realm = try RedPacketService.realm()
                    guard let _redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
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
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { creationSuccess in
                do {
                    let realm = try RedPacketService.realm()
                    guard let redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
                        return
                    }
                    
                    guard redPacket.status == .pending else {
                        os_log("%{public}s[%{public}ld], %{public}s: discard change due to red packet status already %s.", ((#file as NSString).lastPathComponent), #line, #function, redPacket.status.rawValue)
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
                    do {
                        let realm = try RedPacketService.realm()
                        guard let redPacket = realm.object(ofType: RedPacket.self, forPrimaryKey: id) else {
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
