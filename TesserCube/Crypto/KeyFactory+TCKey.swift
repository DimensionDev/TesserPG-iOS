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

extension KeyFactory {

    static func key(from armoredKey: String, passphrase: String?) throws -> TCKey {
        do {
            let keyRing = try DMSPGPKeyRing(armoredKey: armoredKey, password: passphrase)
            let key = TCKey(keyRing: keyRing, from: nil)

            // Check passphrase if there is secret key within
            if let secretKeyRing = key.keyRing.secretKeyRing {
                guard let password = passphrase, secretKeyRing.verify(password: password) else {
                    throw TCError.pgpKeyError(reason: .invalidPassword)
                }

                // passphrase is correct
            }

            return key

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
            let factory = try DMSPGPKeyRingFactory(generateKeyData: generateKeyData)
            let key = TCKey(keyRing: factory.keyRing, from: nil)
            return key
        } catch let error as DMSPGPError {
            consolePrint(error.localizedDescription)
            throw TCError.pgpKeyError(reason: .failToGenerate)
        } catch let error {
            throw error
        }
    }

}
