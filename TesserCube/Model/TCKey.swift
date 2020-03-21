//
//  TCKey.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/20.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import DMSGoPGP

struct TCKey: KeychianMappable, Equatable {
    
    var goKeyRing: CryptoKeyRing?

    /// Primary key userID.
    /// If multiple key exists in keyRing. Only return the first key userID
    var userID: String {
        return userIDs.first?.first ?? ""
    }
    
    /// Exports every key entities' userIDs from keyRing.
    /// Multiple [String] return when more than one entities in the keyRing
    var userIDs: [[String]] {
        var userIDList = [[String]]()
        
        guard let goKeyRing = goKeyRing else {
            return userIDList
        }
        
        for i in 0 ..< goKeyRing.getEntitiesCount() {
            guard let entity = try? goKeyRing.getEntity(i) else {
                continue
            }
            guard entity.getIdentityCount() > 0 else {
                continue
            }
            
            var primaryUserID: String?
            var nonPrimaryUserIDs: [String] = []
            for idIndex in 0 ..< entity.getIdentityCount() {
                guard let identity = try? entity.getIdentity(idIndex) else {
                    continue
                }
                
                // TODO: export Go interface
                // Ref: https://tools.ietf.org/html/rfc4880#section-5.2.3.19
                // let isPrimaryUserID = identity.selfSignature.isPrimaryId
                
                let isPrimaryUserID = false
                if isPrimaryUserID {
                    primaryUserID = identity.name
                } else {
                    nonPrimaryUserIDs.append(identity.name)
                }
            }
            
            // append entity userIDs in list. Take primary userID first
            let userIdsForEntiry = [
                [primaryUserID].compactMap { $0 },
                nonPrimaryUserIDs
            ].flatMap { $0 }
            
            userIDList.append(userIdsForEntiry)
        }
        
        return userIDList
    }
    
    var keyID: String {
        let keyIDString = try? goKeyRing?.getEntity(0).primaryKey?.getId()
        return keyIDString ?? ""
    }
    var longIdentifier: String {
        let longId = try? goKeyRing?.getEntity(0).primaryKey?.keyIdString() ?? ""
        return longId ?? ""
    }
    
    var shortIdentifier: String {
        let shortId = try? goKeyRing?.getEntity(0).primaryKey?.keyIdShortString() ?? ""
        return shortId ?? ""
    }
    
    init?(armored: String) {
        guard let keyRing = try? CryptoGetGopenPGP()?.buildKeyRingArmored(armored) else {
            return nil
        }
        self.init(keyRing: keyRing)
    }
    
    init(keyRing: CryptoKeyRing) {
        self.goKeyRing = keyRing
    }

    func unlock(passphrase: String) throws {
        do {
            try goKeyRing?.unlock(withPassphrase: passphrase)
        } catch {
            throw error
        }
    }
    
    static func == (lhs: TCKey, rhs: TCKey) -> Bool {
        return lhs.keyID == rhs.keyID
    }
}

extension TCKey {
    
    var name: String {
        let name = try? goKeyRing?.getEntity(0).getIdentity(0).userId?.getName() ?? ""
        return name ?? ""
    }

    // Should not construct secret only KeyRing
    var hasPublicKey: Bool {
        let primaryKey = try? goKeyRing?.getEntity(0).primaryKey ?? nil
        return primaryKey != nil
    }

    var hasSecretKey: Bool {
        let privateKey = try? goKeyRing?.getEntity(0).privateKey ?? nil
        return privateKey != nil
    }
    
    var hasPrimaryEncryptionKey: Bool {
        do {
            let primaryEncryptionKey = try goKeyRing?.getEncryptionKey()
            return primaryEncryptionKey != nil
        } catch {
            return false
        }
    }
    
    var encryptionkeyID: String? {
        do {
            return try goKeyRing?.getEncryptionKey().keyIdString()
        } catch {
            return nil
        }
    }
    
    var publicArmored: String? {
        do {
            var error: NSError?
            let armoredPublicKey = goKeyRing?.getArmoredPublicKey(&error)
            if let error = error {
                throw error
            }
            return armoredPublicKey
        } catch {
            return nil
        }
    }
    
    func getPrivateArmored(passprahse: String?) throws -> String? {
        do {
            var error: NSError?
            try? goKeyRing?.unlock(withPassphrase: passprahse)
            let armoredKeyRing = goKeyRing?.getArmored(passprahse, error: &error) ?? ""
            if error != nil {
                throw TCError.pgpKeyError(reason: .invalidPassword)
            }
            return armoredKeyRing
        } catch {
            return nil
        }
    }
    
    func getDecryptingKeyIDs() -> [String] {
        var keyIds: [String] = []
        for entityIndex in 0 ..< (goKeyRing?.getEntitiesCount() ?? 0) {
            if let entity = try? goKeyRing?.getEntity(entityIndex) {
                if let privateKey = entity.privateKey {
                    keyIds.append(privateKey.getId())
                }
            }
        }
        return keyIds
    }

    var fingerprint: String {
        let fingerprint = try? goKeyRing?.getEntity(0).primaryKey?.getFingerprint()
        return fingerprint ?? ""
    }

    var displayFingerprint: String? {
        let splited = fingerprint.separate(every: 4, with: " ").split(separator: " ")
        guard splited.count == 10 else {
            return nil
        }
        let firstPart = splited[0..<5]
        let secondPart = splited[5..<10]
        let firstPartResult = firstPart.joined(separator: " ")
        let secondPartResult = secondPart.joined(separator: " ")
        let finalResult = firstPartResult.appending("\n").appending(secondPartResult)
        return finalResult
    }

    var creationDate: Date? {
        if let timestamp = try? goKeyRing?.getEntity(0).primaryKey?.getCreationTimestamp() {
            return Date(timeIntervalSince1970: TimeInterval(timestamp))
        }
        return nil
    }

    /// primary key algorithm
    var primaryKeyAlgorihm: PublicKeyAlgorithm? {
        return try? goKeyRing?.getEntity(0).primaryKey?.algorithm
    }

    /// primary key length in bit
    var primaryKeyStrength: Int? {
        var bitLenghtInt = 0
        try? goKeyRing?.getEntity(0).primaryKey?.getBitLength(&bitLenghtInt)
        return bitLenghtInt
    }
    
    var isValid: Bool {
        var expired: ObjCBool = false
        try? CryptoGetGopenPGP()?.isKeyExpired(goKeyRing?.getPublicKey(), ret0_: &expired)
        return !expired.boolValue
    }
}

// MARK: - Subkey management
extension TCKey {
    
    var hasSubkey: Bool {
        guard let subKeyCount = try? goKeyRing?.getEntity(0).getSubkeyCount() else {
            return false
        }
        return subKeyCount > 0
    }
    
    var subkeyStrength: Int? {
        guard hasSubkey else { return nil }
        
        if let primaryEncryptionKey = try? goKeyRing?.getEncryptionKey() {
            var primaryEncryptionKeybitLenghtInt = 0
            try? primaryEncryptionKey.getBitLength(&primaryEncryptionKeybitLenghtInt)
        }
        
        if let firstSubKey = try? goKeyRing?.getEntity(0).getSubkey(0) {
            var bitLenghtInt = 0
            try? firstSubKey.publicKey?.getBitLength(&bitLenghtInt)
            return bitLenghtInt
        }
        return nil
    }
    
    var subkeyAlgorithm: PublicKeyAlgorithm? {
        guard hasSubkey else { return nil }
        if let primaryEncryptionKey = try? goKeyRing?.getEncryptionKey() {
            let primaryAlgo = primaryEncryptionKey.algorithm
            print("TEST ALGO")
        }
        
        if let firstSubKey = try? goKeyRing?.getEntity(0).getSubkey(0) {
            return firstSubKey.publicKey?.algorithm
        }
        return nil
    }
}

extension TCKey {
    
    var entities: [CryptoKeyEntity] {
        guard let goKeyRing = goKeyRing else { return [] }
        
        var entities: [CryptoKeyEntity] = []
        for i in 0 ..< goKeyRing.getEntitiesCount() {
            guard let entity = try? goKeyRing.getEntity(i) else {
                continue
            }
            
            entities.append(entity)
        }
        
        return entities
    }
    
}
