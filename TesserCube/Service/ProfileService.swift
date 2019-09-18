//
//  ProfileService.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/18.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import DMSOpenPGP
import RxSwift
import RxCocoa
import KeychainAccess
import GRDB
import ConsolePrint

class ProfileService {
    
    public static let `default` = ProfileService()

    let keys: BehaviorRelay<[TCKey]>
    let contacts: BehaviorRelay<[Contact]>
    let messages: BehaviorRelay<[Message]>

    let contactChanged = PublishRelay<[Int64]>()
    let messageChanged = PublishRelay<Int64>()
    
    private var keyRecordsObervation: TransactionObserver?
    private var contactsObervation: TransactionObserver?
    private var messagesObervation: TransactionObserver?

    #if XCTEST
    // For simulator
    let keyChain = Keychain(service: "com.Sujitech.TesserCube", accessGroup: "7LFDZ96332.com.Sujitech.TesserCube")
    #else
    let keyChain = Keychain(service: "com.Sujitech.TesserCube", accessGroup: "7LFDZ96332.com.Sujitech.TesserCube").accessibility(.afterFirstUnlock, authenticationPolicy: .userPresence)
    #endif

    private let disposeBag = DisposeBag()
    
    init() {
        keys = BehaviorRelay(value: [])
        contacts = BehaviorRelay(value: [])
        messages = BehaviorRelay(value: [])

        // Key

        // swiftlint:disable force_try
        keyRecordsObervation = try! ValueObservation.trackingAll(KeyRecord.all())
            .start(in: TCDBManager.default.dbQueue, onChange: { latestKeyRecords in
                let keys = latestKeyRecords.compactMap { record -> TCKey? in
                    guard let armored = record.armored,
                    let keyRing = try? DMSPGPKeyRing(armoredKey: armored) else {
                        return nil
                    }

                    return TCKey(keyRing: keyRing, from: record)
                }
                self.keys.accept(keys)

                #if TARGET_IS_EXTENSION
                let identifier = WormholdService.MessageIdentifier.notifyAppUpdateKeys
                #else
                let identifier = WormholdService.MessageIdentifier.notifyExtensionUpdateKeys
                #endif
                WormholdService.shared.wormhole.clearMessageContents(forIdentifier: identifier.rawValue)
                WormholdService.shared.wormhole.passMessageObject(identifier.rawValue as NSCoding, identifier: identifier.rawValue)

            })
        // swiftlint:enable force_try

        #if TARGET_IS_EXTENSION
        let keysUpdateIdentifier = WormholdService.MessageIdentifier.notifyExtensionUpdateKeys
        #else
        let keysUpdateIdentifier = WormholdService.MessageIdentifier.notifyAppUpdateKeys
        #endif
        WormholdService.shared.listeningWormhole.listenForMessage(withIdentifier: keysUpdateIdentifier.rawValue) { [weak self] _ in
            guard let `self` = self else { return }
            let keys = KeyRecord.all().compactMap { record -> TCKey? in
                guard let armored = record.armored,
                let keyRing = try? DMSPGPKeyRing(armoredKey: armored) else {
                    return nil
                }

                return TCKey(keyRing: keyRing, from: record)
            }
            self.keys.accept(keys)
        }

        // Contact

        // swiftlint:disable force_try
        contactsObervation = try! ValueObservation.trackingAll(Contact.all())
            .start(in: TCDBManager.default.dbQueue, onChange: { latestContacts in
                self.contacts.accept(latestContacts)

                #if TARGET_IS_EXTENSION
                let identifier = WormholdService.MessageIdentifier.notifyAppUpdateContacts
                #else
                let identifier = WormholdService.MessageIdentifier.notifyExtensionUpdateContacts
                #endif
                WormholdService.shared.wormhole.clearMessageContents(forIdentifier: identifier.rawValue)
                WormholdService.shared.wormhole.passMessageObject(identifier.rawValue as NSCoding, identifier: identifier.rawValue)
            })
        // swiftlint:enable force_try

        #if TARGET_IS_EXTENSION
        let contactsUpdateIdentifier = WormholdService.MessageIdentifier.notifyExtensionUpdateContacts
        #else
        let contactsUpdateIdentifier = WormholdService.MessageIdentifier.notifyAppUpdateContacts
        #endif
        WormholdService.shared.listeningWormhole.listenForMessage(withIdentifier: contactsUpdateIdentifier.rawValue) { [weak self] _ in
            guard let `self` = self else { return }
            self.contacts.accept(Contact.all())
        }

        contactChanged
            .subscribe(onNext: { contactIds in
                var currentContacts = self.contacts.value
                contactIds.forEach { contactId in
                    if let existContactIndex = currentContacts.firstIndex(where: { ($0.id ?? -1) == contactId } ),
                    let updatedContact = Contact.find(id: contactId) {
                        currentContacts[existContactIndex] = updatedContact
                    }
                }
                self.contacts.accept(currentContacts)
            })
            .disposed(by: disposeBag)


        // Message

        // swiftlint:disable force_try
        messagesObervation = try! ValueObservation.trackingAll(Message.all())
            .start(in: TCDBManager.default.dbQueue, onChange: { latestMessages in
                self.messages.accept(latestMessages)

                #if TARGET_IS_EXTENSION
                let identifier = WormholdService.MessageIdentifier.notifyAppUpdateMessage
                #else
                let identifier = WormholdService.MessageIdentifier.notifyExtensionUpdateMessage
                #endif
                WormholdService.shared.wormhole.clearMessageContents(forIdentifier: identifier.rawValue)
                WormholdService.shared.wormhole.passMessageObject(identifier.rawValue as NSCoding, identifier: identifier.rawValue)
            })
        // swiftlint:enable force_try

        #if TARGET_IS_EXTENSION
        let messagesUpdateIdentifier = WormholdService.MessageIdentifier.notifyExtensionUpdateMessage
        #else
        let messagesUpdateIdentifier = WormholdService.MessageIdentifier.notifyAppUpdateMessage
        #endif
        WormholdService.shared.listeningWormhole.listenForMessage(withIdentifier: messagesUpdateIdentifier.rawValue) { [weak self] _ in
            guard let `self` = self else { return }
            self.messages.accept(Message.all())
        }

        messageChanged
            .subscribe(onNext: { messageID in
                var currentMessages = self.messages.value
                if let index = currentMessages.firstIndex(where: { ($0.id ?? -1) == messageID } ),
                let updateMessage = Message.loadMessage(id: messageID) {
                    currentMessages[index] = updateMessage
                }
                self.messages.accept(currentMessages)
            })
            .disposed(by: disposeBag)
    }

}

extension ProfileService {

    /// Default signature key in keyboard
    var defaultSignatureKey: TCKey? {
        return keys.value.first(where: { key in
            return key.hasSecretKey && key.hasPublicKey
        })
    }

}

extension ProfileService {

    func containsKey(longIdentifier: String) -> Bool {
        return keys.value.contains(where: { key in
            return key.longIdentifier == longIdentifier
        })
    }
    
}
