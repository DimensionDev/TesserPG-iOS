//
//  InterpretActionViewModel.swift
//  TesserCubeInterpretAction
//
//  Created by Cirno MainasuK on 2019-7-17.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

final class InterpretActionViewModel: NSObject {

    private let disposeBag = DisposeBag()

    // Input
    var inputTexts: [String] = []
    var copyAction = PublishRelay<UIButton>()
    var replyAction = PublishRelay<UIButton>()
    var composedMessage = BehaviorRelay<Message?>(value: nil)

    // Output
    let title = BehaviorRelay<String>(value: L10n.InterpretActionViewController.Title.messageInterpreting)
    let armoredMessage = BehaviorRelay<String?>(value: nil)
    let interpretedMessage = BehaviorRelay<Message?>(value: nil)
    let messages: Driver<[Message]>

    override init() {
        messages = Driver.combineLatest(interpretedMessage.asDriver(), composedMessage.asDriver()) { interpretedMessage, composedMessage in
            return [interpretedMessage, composedMessage].compactMap { $0 }
        }

        super.init()

        armoredMessage.asDriver()
            .flatMapLatest { message in
                return Driver.just(message.flatMap { try? ProfileService.default.decryptMessage($0) })
            }
            .drive(interpretedMessage)
            .disposed(by: disposeBag)

        interpretedMessage.asDriver()
            .skip(1)
            .drive(onNext: { message in
                let title = message != nil ? L10n.InterpretActionViewController.Title.messageInterpreted : L10n.InterpretActionViewController.Title.brokenMessage
                self.title.accept(title)
            })
            .disposed(by: disposeBag)

    }   // end init()

}

extension InterpretActionViewModel {

    func finalizeInput() {
        // Prevent user change messages database in main app cause database not sync between app and extension.
        ProfileService.default.messages.accept(Message.all())

        let message = inputTexts.first { KeyFactory.verify(armoredMessage: $0) }
        armoredMessage.accept(message)
    }

}
