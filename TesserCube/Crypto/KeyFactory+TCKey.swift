//
//  KeyFactory+TCKey.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-5-23.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import DMSOpenPGP
import ConsolePrint
import DMSGoPGP

extension KeyFactory {

    static func key(from armoredKey: String, passphrase: String?) throws -> TCKey {
        do {
            guard let keyRing = try? DMSPGPKeyRing(armoredKey: armoredKey, password: passphrase) else {
                throw TCError.pgpKeyError(reason: .invalidKeyFormat)
            }
            let key = TCKey(keyRing: keyRing)

            // Check passphrase if there is secret key within
            if let secretKeyRing = key.keyRing.secretKeyRing {
                guard let password = passphrase, secretKeyRing.verify(password: password) else {
                    throw TCError.pgpKeyError(reason: .invalidPassword)
                }

                // passphrase is correct
            }

            return key

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
            let factory = try DMSPGPKeyRingFactory(generateKeyData: generateKeyData)
            var key = TCKey(keyRing: factory.keyRing)
            
            let goKey = CryptoGetGopenPGP()?.generateKey(generateKeyData.name, email: generateKeyData.email, passphrase: generateKeyData.password, keyType: "rsa", bits: 3072, error: nil)
            let goKeyRing = try? CryptoGetGopenPGP()?.buildKeyRingArmored(goKey!)
            key.goKeyRing = goKeyRing
            key.unlock(passphrase: "123456")
            
            return key
        } catch let error as DMSPGPError {
            consolePrint(error.localizedDescription)
            throw TCError.pgpKeyError(reason: .failToGenerate)
        } catch let error {
            throw error
        }
    }

}
