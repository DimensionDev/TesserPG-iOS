//
//  TCKey.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/20.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import BouncyCastle_ObjC
import DMSOpenPGP
import DMSGoPGP

struct TCKey: KeychianMappable {

    let keyRing: DMSPGPKeyRing
    
    var goKeyRing: CryptoKeyRing?

    var userID: String {
        let keyID = try? goKeyRing?.getEntity(0).getIdentity(0).name ?? ""
        return keyID ?? ""
        return keyRing.publicKeyRing.primaryKey.primaryUserID ?? ""
    }
    var keyID: String {
        let keyIdInt = try? goKeyRing?.getEntity(0).primaryKey?.getId() ?? 0
        return String(keyIdInt ?? 0)
        return keyRing.publicKeyRing.primaryKey.keyID
    }
    var longIdentifier: String {
        let longId = try? goKeyRing?.getEntity(0).primaryKey?.keyIdString() ?? ""
        return longId ?? ""
        return keyRing.publicKeyRing.primaryKey.longIdentifier
    }
    
    var shortIdentifier: String {
        let shortId = try? goKeyRing?.getEntity(0).primaryKey?.keyIdShortString() ?? ""
        return shortId ?? ""
        return keyRing.publicKeyRing.primaryKey.shortIdentifier
    }

    init(keyRing: DMSPGPKeyRing) {
        self.keyRing = keyRing
    }

    func unlock(passphrase: String) {
        try? goKeyRing?.unlock(withPassphrase: passphrase)
    }
}

extension TCKey {
    
    var name: String {
        let name = try? goKeyRing?.getEntity(0).getIdentity(0).userId?.getName() ?? ""
        return name ?? ""
        return PGPUserIDTranslator(userID: userID).name ?? ""
    }

    // Should not construct secret only KeyRing
    var hasPublicKey: Bool {
        let primaryKey = try? goKeyRing?.getEntity(0).primaryKey ?? nil
        return primaryKey != nil
        return true
    }

    var hasSecretKey: Bool {
        let privateKey = try? goKeyRing?.getEntity(0).privateKey ?? nil
        return privateKey != nil
        return keyRing.secretKeyRing != nil
    }

    var armored: String {
        let armoredKeyRing = goKeyRing?.getArmored("123456", error: nil) ?? ""
        return armoredKeyRing
        var armored = keyRing.publicKeyRing.armored()
        if let secretKeyArmored = keyRing.secretKeyRing?.armored() {
            armored.append(contentsOf: secretKeyArmored)
        }

        return armored
    }

    var fingerprint: String {
        let fingerprint = try? goKeyRing?.getEntity(0).primaryKey?.getFingerprint().uppercased()
        return fingerprint ?? ""
        return keyRing.publicKeyRing.primaryKey.fingerprint
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
        return keyRing.publicKeyRing.primaryKey.creationDate
    }
    
    var algorithm: DMSPGPPublicKeyAlgorithm? {
        return keyRing.publicKeyRing.primaryEncryptionKey?.algorithm
    }

    var keyStrength: Int? {
        var bitLenghtInt = 0
        try? goKeyRing?.getEntity(0).primaryKey?.getBitLength(&bitLenghtInt)
        return bitLenghtInt
        return keyRing.publicKeyRing.primaryEncryptionKey?.keyStrength
    }
    
    var isValid: Bool {
        return keyRing.publicKeyRing.primaryKey.isValid
    }
}

//MARK: Subkey management
extension TCKey {
    
    var hasSubkey: Bool {
        return !keyRing.publicKeyRing.encryptionKeys.isEmpty
    }
    
    var subkeyStrength: Int? {
        guard let firstSubkey = keyRing.publicKeyRing.encryptionKeys.first else {
            return nil
        }
        return firstSubkey.keyStrength
    }
    
    var subkeyAlgorithm: DMSPGPPublicKeyAlgorithm? {
        guard let firstSubkey = keyRing.publicKeyRing.encryptionKeys.first else {
            return nil
        }
        return firstSubkey.algorithm
    }
}
