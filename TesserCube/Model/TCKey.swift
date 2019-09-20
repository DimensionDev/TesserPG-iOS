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

    var userID: String {
        let keyID = try? goKeyRing?.getEntity(0).getIdentity(0).name ?? ""
        return keyID ?? ""
    }
    
    var userIDs: [String] {
        var userIDList = [String]()
        for i in 0 ..< (goKeyRing?.getEntitiesCount() ?? 0) {
            let entity = try? goKeyRing?.getEntity(i)
            for n in 0 ..< (entity?.getIdentityCount() ?? 0) {
                if let identity = try? entity?.getIdentity(n) {
                    userIDList.append(identity.name)
                }
            }
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
            if let error = error {
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

//MARK: Subkey management
extension TCKey {
    
    var hasSubkey: Bool {
        return false
//        goKeyRing?.getEntity(0).privateKey
//        return !keyRing.publicKeyRing.encryptionKeys.isEmpty
    }
    
    var subkeyStrength: Int? {
        return 0
//        guard let firstSubkey = keyRing.publicKeyRing.encryptionKeys.first else {
//            return nil
//        }
//        return firstSubkey.keyStrength
    }
    
    var subkeyAlgorithm: KeyAlgorithm? {
        return .rsa
//        guard let firstSubkey = keyRing.publicKeyRing.encryptionKeys.first else {
//            return nil
//        }
//        return firstSubkey.algorithm
//    }
    }
}
