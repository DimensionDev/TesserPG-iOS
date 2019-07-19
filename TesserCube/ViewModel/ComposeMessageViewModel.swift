//
//  ComposeMessageViewModel.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-3-25.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

// Entry:
// 1. recompose: set message
// 2. edit draft: set message
// 3. compose to contact: set keyBridges
// 4. write reply: set keyBridges and
final class ComposeMessageViewModel: NSObject {

    let disposeBag = DisposeBag()

    // Input
    let viewDidAppear = BehaviorRelay<Bool>(value: false)
    let message = BehaviorRelay<Message?>(value: nil)           // for restore
    var senderKeyBridge: KeyBridge?                             // for restore

    // Output
    let keyBridges = BehaviorRelay<[KeyBridge]>(value: [])      // bind to RecipientContactPickerView
    let rawMessage = BehaviorRelay(value: "")                   // bind to messageTextFiled

    enum TableViewCell: CaseIterable {
        case to
        case from
        case message
    }

}

extension ComposeMessageViewModel {

    static func composeMessage(_ rawMessage: String, to recipients: [TCKey], from sender: TCKey?, password: String? = nil) -> Single<String> {
        let editingMessage = rawMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !editingMessage.isEmpty else {
            return Single.error(TCError.composeError(reason: .emptyInput))
        }

        return Single<String>.create { single in
            guard !(recipients.isEmpty && sender == nil) else {
                single(.error(TCError.composeError(reason: .emptySenderAndRecipients)))
                return Disposables.create()
            }
            do {
                if recipients.isEmpty, let signatureKey = sender {
                    let signed = try KeyFactory.clearsignMessage(editingMessage, signatureKey: signatureKey)
                    single(.success(signed))
                } else {
                    let encrypted = try KeyFactory.encryptMessage(editingMessage, signatureKey: sender, recipients: recipients)
                    single(.success(encrypted))
                }
            } catch {
                single(.error(error))
            }

            return Disposables.create()
        }
    }
    
}
