//
//  ProfileService+KeyRecord.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-9-3.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import DMSGoPGP

extension ProfileService {
    
    func addNewKey(userID: String, passphrase: String?, generateKeyData: GenerateKeyData, _ completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                let newKey = try KeyFactory.key(from: generateKeyData)
                
                // TODO: KeyRecord insert here. Should Refactoring here when we support sub-key feature
                try self.addNewContact(keyUserID: userID, key: newKey, passphrase: passphrase)
                
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
                    let userID = key.userID

                    // TODO: KeyRecord insert here. Should Refactoring here when we support sub-key feature
                    try self.addNewContact(keyUserID: userID, key: key, passphrase: passphrase)

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
                DispatchQueue.main.async {
                    completion(key, nil)
                }
            } catch let error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }

    /// Add key entities into the database from the keyRing in TCKey
    ///
    /// Note:
    ///   The TCKey could contains multiple keys from other PGP clients.
    ///   This function take every single key entity and create new contract.
    ///
    /// Warning:
    ///   Not supports import multiple private key entities just now.
    ///
    /// - Parameters:
    ///   - tckey: keyRing wrapper. May contains multiple entities if create from user input aromor
    ///   - passphrase: passphrase for key tcKey. Set nil for import only public part
    ///   - completion: error callback
    func addKey(_ tckey: TCKey, passphrase: String?, _ completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                // throw error when import multiple entities
                if passphrase != nil {
                    guard tckey.userIDs.count == 1 else {
                        DispatchQueue.main.async {
                            completion(TCError.pgpKeyError(reason: TCError.PGPKeyErrorReason.notSupportAddMultiplePrivateKey))
                        }
                        return
                    }
                }
                
                guard let keyRing = tckey.goKeyRing else {
                    completion(TCError.pgpKeyError(reason: TCError.PGPKeyErrorReason.invalidKeyFormat))
                    return
                }
                
                for i in 0 ..< keyRing.getEntitiesCount() {
                    guard let entity = try? keyRing.getEntity(i) else { continue }
                    guard let newKeyRing = CryptoNewKeyRing() else { continue}
                    
                    do {
                        try newKeyRing.add(entity)
                    } catch {
                        continue
                    }
                    
                    let newTCKey = TCKey(keyRing: newKeyRing)
                    
                    // skip if already added
                    guard !self.keys.value.contains(where: { $0.longIdentifier == newTCKey.longIdentifier }) else {
                        continue
                    }
                    
                    // The insert process will be terminal if throw error.
                    let userID = newTCKey.userID
                    try self.addNewContact(keyUserID: userID, key: newTCKey, passphrase: passphrase)
                }
                
                try self.keyChain
                    .authenticationPrompt("Authenticate to update your password")
                    .set(passphrase ?? "", key: tckey.longIdentifier)
                
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch let error {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }
    
    /// Update partial public keypair to secret key pair
    /// - Parameters:
    ///   - tcKey: secret keypair for updaate
    ///   - passphrase: passphrase for tcKey
    ///   - completion: error callback
    func updateKey(_ tcKey: TCKey, passphrase: String, _ completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                // keyRecordsObervation will handle database update
                guard var keyRecord = KeyRecord.all().first(where: { $0.longIdentifier == tcKey.longIdentifier }) else {
                    completion(nil)
                    return
                }
                try keyRecord.updateKey(tcKey, passphrase: passphrase)
                
                completion(nil)
                
            } catch {
                completion(error)
            }
        }
    }
    
}
