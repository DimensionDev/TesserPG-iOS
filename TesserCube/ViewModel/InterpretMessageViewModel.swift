//
//  InterpretMessageViewModel.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-3-30.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

final class InterpretMessageViewModel {
    
    let disposeBag = DisposeBag()
    
    // Input
    let myKeys = BehaviorRelay<[TCKey]>(value: [])
    let message = BehaviorRelay<String>(value: "")
    
    init() {
        ProfileService.default.keys.asDriver()
            .map { $0.filter { $0.hasSecretKey && $0.hasPublicKey } }
            .drive(myKeys)
            .disposed(by: disposeBag)
    }
}

extension InterpretMessageViewModel {

    func interpretMessage() -> Single<Message> {
        do {
            let decryptedMessage = try ProfileService.default.decryptMessage(self.message.value)
            return .just(decryptedMessage)
            return .never()
        } catch {
            return .error(error)
        }
    }
    
}
