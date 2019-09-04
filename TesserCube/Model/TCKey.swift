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

struct TCKey: KeychianMappable {

    // Not databae detached key should set keyRecord
    let keyRecord: KeyRecord?

    let keyRing: DMSPGPKeyRing

    var userID: String {
        return keyRing.publicKeyRing.primaryKey.primaryUserID ?? ""
    }
    var keyID: String {
        return keyRing.publicKeyRing.primaryKey.keyID
    }
    var longIdentifier: String {
        return keyRing.publicKeyRing.primaryKey.longIdentifier
    }
    
    var shortIdentifier: String {
        return keyRing.publicKeyRing.primaryKey.shortIdentifier
    }

    init(keyRing: DMSPGPKeyRing, from keyRecord: KeyRecord?) {
        self.keyRecord = keyRecord
        self.keyRing = keyRing
    }

}

extension TCKey {
    
    var name: String {
        return PGPUserIDTranslator(userID: userID).name ?? ""
    }

    // Should not construct secret only KeyRing
    var hasPublicKey: Bool {
        return true
    }

    var hasSecretKey: Bool {
        return keyRing.secretKeyRing != nil
    }

    var armored: String {
        var armored = keyRing.publicKeyRing.armored()
        if let secretKeyArmored = keyRing.secretKeyRing?.armored() {
            armored.append(contentsOf: secretKeyArmored)
        }

        return armored
    }

    var fingerprint: String {
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
