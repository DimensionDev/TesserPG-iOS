//
//  KeyFactory+TCKey.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-5-23.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import ConsolePrint
import DMSGoPGP

extension KeyFactory {

    static func key(from armoredKey: String, passphrase: String?) throws -> TCKey {
        do {
//<<<<<<< HEAD
//            guard let keyRing = try? DMSPGPKeyRing(armoredKey: armoredKey, password: passphrase) else {
//                throw TCError.pgpKeyError(reason: .invalidKeyFormat)
//            }
//            let key = TCKey(keyRing: keyRing)
            guard let key = TCKey(armored: armoredKey), try key.goKeyRing?.getEncryptionKey() != nil else {
                throw TCError.pgpKeyError(reason: .invalidPassword)
            }
            if let passphrase = passphrase {
                try key.unlock(passphrase: passphrase)
//=======
//            let keyRing = try DMSPGPKeyRing(armoredKey: armoredKey, password: passphrase)
//            let key = TCKey(keyRing: keyRing, from: nil)
//
//            // Check passphrase if there is secret key within
//            if let secretKeyRing = key.keyRing.secretKeyRing {
//                guard let password = passphrase, secretKeyRing.verify(password: password) else {
//                    throw TCError.pgpKeyError(reason: .invalidPassword)
//                }
//
//                // passphrase is correct
//>>>>>>> 949ca18... fix: not prompt "invalid password" when import private key with wrong passphrase issue
            }
            
            return key
            // Check passphrase if there is secret key within
//            if let secretKeyRing = key.keyRing.secretKeyRing {
//                guard let password = passphrase, secretKeyRing.verify(password: password) else {
//                    throw TCError.pgpKeyError(reason: .invalidPassword)
//                }
//
//                // passphrase is correct
//            }
//
//            return key

        } catch DMSPGPError.invalidSecrectKeyPassword {
            throw TCError.pgpKeyError(reason: .invalidPassword)
        } catch let error as DMSPGPError {
            consolePrint(error.localizedDescription)
            throw TCError.pgpKeyError(reason: .invalidKeyFormat)
        } catch {
            consolePrint(error.localizedDescription)
            throw error
        }
    }

    static func key(from generateKeyData: GenerateKeyData) throws -> TCKey {
        do {
            guard let goKey = CryptoGetGopenPGP()?.generateKey(generateKeyData.name,
                                                         email: generateKeyData.email,
                                                         passphrase: generateKeyData.password,
                                                         keyType: generateKeyData.masterKey.algorithm.rawValue,
                                                         bits: generateKeyData.masterKey.strength,
                                                         error: nil),
            let goKeyRing = try? CryptoGetGopenPGP()?.buildKeyRingArmored(goKey) else {
                throw TCError.pgpKeyError(reason: .failToGenerate)
            }

            let key = TCKey(keyRing: goKeyRing)
            // try key.unlock(passphrase: generateKeyData.password)
            
            return key
        } catch let error as DMSPGPError {
            consolePrint(error.localizedDescription)
            throw TCError.pgpKeyError(reason: .failToGenerate)
        } catch let error {
            throw error
        }
    }

}
