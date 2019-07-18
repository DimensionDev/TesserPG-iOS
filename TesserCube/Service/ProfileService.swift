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
    
    let contactKeyPairs = BehaviorRelay<[(Contact, [TCKey])]>(value: [])
    let keys: BehaviorRelay<[TCKey]>
    let contacts: BehaviorRelay<[Contact]>
    let messages: BehaviorRelay<[Message]>

    let contactChanged = PublishRelay<[Int64]>()
    let messageChanged = PublishRelay<Int64>()
    
    private var contactsObervation: TransactionObserver?
    private var messagesObervation: TransactionObserver?
    private var keysObervation: TransactionObserver?
    
    let keyChain = Keychain(service: "com.Sujitech.TesserCube", accessGroup: "7LFDZ96332.com.Sujitech.TesserCube").accessibility(.afterFirstUnlock, authenticationPolicy: .userPresence)
    
    private let disposeBag = DisposeBag()
    
    init() {
        keys = BehaviorRelay(value: [])
        messages = BehaviorRelay(value: [])
        contacts = BehaviorRelay(value: [])

        contactKeyPairs.asDriver()
            .map { pairs in pairs.flatMap { $0.1 } }
            .drive(keys)
            .disposed(by: disposeBag)

        keys.asDriver()
            .drive(onNext: { _ in
                WormholdService.shared.wormhole.clearMessageContents(forIdentifier: WormholdService.MessageIdentifier.appDidUpdateKeys.rawValue)
                WormholdService.shared.wormhole.passMessageObject("appDidUpdateKeys" as NSCoding, identifier: WormholdService.MessageIdentifier.appDidUpdateKeys.rawValue)
                NSLog("WormholdService.MessageIdentifier.appDidUpdateKeys")
            })
            .disposed(by: disposeBag)
        
        // swiftlint:disable force_try
        contactsObervation = try! ValueObservation.trackingAll(Contact.all())
            .start(in: TCDBManager.default.dbQueue, onChange: { latestContacts in
                self.contacts.accept(latestContacts)
            })
        
        messagesObervation = try! ValueObservation.trackingAll(Message.all())
            .start(in: TCDBManager.default.dbQueue, onChange: { latestMessages in
                self.messages.accept(latestMessages)
            })
        
        keysObervation = try! ValueObservation.trackingAll(KeyRecord.all())
            .start(in: TCDBManager.default.dbQueue, onChange: { latestKeyRecords in
                let contacts = self.contacts.value
                let pairs = contacts.map { contact in
                    return (contact, contact.getKeys())
                }
                self.contactKeyPairs.accept(pairs)
            })
        // swiftlint:enable force_try
        
        contactChanged
            .subscribe(onNext: { contactIds in
                var currentContacts = self.contacts.value
                contactIds.forEach { contactId in
                    if let existContactIndex = currentContacts.firstIndex(where: { ($0.id ?? -1) == contactId } ),
                    let updatedContact = Contact.loadContact(id: contactId) {
                        currentContacts[existContactIndex] = updatedContact
                    }
                }
                self.contacts.accept(currentContacts)
            })
            .disposed(by: disposeBag)

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

        WormholdService.shared.listeningWormhole.listenForMessage(withIdentifier: WormholdService.MessageIdentifier.keyboardDidEncryptMessage.rawValue) { [weak self] _ in
            guard let `self` = self else { return }
            let messages = self.loadMessages()
            self.messages.accept(messages)
            NSLog("WormholdService.MessageIdentifier.keyboardDidEncryptMessage")
        }
    }

    func addNewKey(userID: String, passphrase: String?, generateKeyData: GenerateKeyData, _ completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                let newKey = try KeyFactory.key(from: generateKeyData)

                // TODO: KeyRecord insert here. Should Refactoring here when we support sub-key feature
                try self.addNewContact(keyUserID: userID, key: newKey)

                // Should be the secret invalidated when passcode is removed? If not then use `.WhenUnlocked`
                try self.keyChain
                    .authenticationPrompt("Authenticate to update your password")
                    .set(passphrase ?? "", key: newKey.longIdentifier)

                completion(nil)
            } catch let error {
                print("error")
                completion(error)
            }
        }
    }
    
    func addNewKey(armoredKey: String, passphrase: String?, _ completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                let key = try KeyFactory.key(from: armoredKey, passphrase: passphrase)

                // TODO: only check contact's keys before add key when we support sub-key feature
                if self.keys.value.contains(where: { $0.longIdentifier == key.longIdentifier }) {
                    throw TCError.keysAlreadyExsit
                }
                // Only create one Contact from key's primary userID
                let userID = key.keyRing.publicKeyRing.primaryKey.primaryUserID ?? ""

                // TODO: KeyRecord insert here. Should Refactoring here when we support sub-key feature
                try self.addNewContact(keyUserID: userID, key: key)

                try self.keyChain
                    .authenticationPrompt("Authenticate to update your password")
                    .set(passphrase ?? "", key: key.longIdentifier)

                var currentKeys = self.keys.value
                currentKeys.append(key)
                self.keys.accept(currentKeys)

                completion(nil)
            } catch let error {
                completion(error)
            }
        }
    }
    
    func decryptKey(armoredKey: String, passphrase: String?, _ completion: @escaping (TCKey?, Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                let key = try KeyFactory.key(from: armoredKey, passphrase: passphrase)
                completion(key, nil)
            } catch let error {
                completion(nil, error)
            }
        }
    }

    func addKey(_ tckey: TCKey, passphrase: String?, _ completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                // Only create one Contact from key's primary userID
                let userIDs = tckey.keyRing.publicKeyRing.primaryKey.userIDs
                
                // TODO: KeyRecord insert here. Should Refactoring here when we support sub-key feature
                try userIDs.forEach { try self.addNewContact(keyUserID: $0, key: tckey) }
                
                try self.keyChain
                    .authenticationPrompt("Authenticate to update your password")
                    .set(passphrase ?? "", key: tckey.longIdentifier)
                
                var currentKeys = self.keys.value
                currentKeys.append(tckey)
                self.keys.accept(currentKeys)
                
                completion(nil)
            } catch let error {
                completion(error)
            }
        }
    }
}

// MARK: Contacts related function
extension ProfileService {
    func addNewContact(keyUserID: String, key: TCKey) throws {
        do {
            let userInfo = PGPUserIDTranslator.extractMeta(from: keyUserID)
            let username = userInfo.name
            let email = userInfo.email
            guard username != nil || email != nil else {
                throw TCError.userInfoError(type: .invalidUserID(userID: keyUserID))
            }

            // contactsObervation will handle database update
            let _ = try TCDBManager.default.dbQueue.write { db -> Contact in
                var newContact = Contact(id: nil, name: username ?? "")
                try newContact.insert(db)
                if let contactId = newContact.id {
                    if let validMail = email {
                        var newEmail = Email(id: nil, address: validMail, contactId: contactId)
                        try newEmail.insert(db)
                    }
                    var newKeyRecord = KeyRecord(id: nil, longIdentifier: key.longIdentifier, hasSecretKey: key.hasSecretKey, hasPublicKey: key.hasPublicKey, contactId: contactId, armored: key.armored)
                    try newKeyRecord.insert(db)
                }
                return newContact
            }   // end let _ = try …

        } catch let error {
            throw error
        }
    }

    func deleteContact(_ contact: Contact) throws {
        do {
            guard let _ = contact.id else {
                assertionFailure("Entity without ID could not to delete")
                return
            }
            _ = try TCDBManager.default.dbQueue.write { db in
                try contact.delete(db)
            }

            // Any key records will be deleted cascade

        } catch let error {
            throw error
        }
    }
    
    func deleteContactSecretKey(_ contact: Contact) throws {
        guard let contactId = contact.id else { return }
        do {
            let keyRecords = contact.getKeyRecords()
            for keyRecord in keyRecords where keyRecord.hasSecretKey {
                var keyRecord = keyRecord
                try keyRecord.removeKeySecretPart()
            }
            ProfileService.default.contactChanged.accept([contactId])
        } catch {
            throw error
        }
    }
}

extension ProfileService {
    
    func loadContacts() -> [Contact] {
        do {
            let contacts = try TCDBManager.default.dbQueue.read({ db in
                try Contact.fetchAll(db)
            })
            return contacts
        } catch let error {
            consolePrint(error.localizedDescription)
            return []
        }
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
