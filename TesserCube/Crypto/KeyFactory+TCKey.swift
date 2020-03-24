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
    
    /// Create TCKey from key armor. Armor contains multiple key is acceptable.
    /// Unlock check will be called if passphrase set not nil.
    ///
    /// Note:
    ///   This factory method passthough armor into the underneath keyRing .
    ///   And not guarantee the application logical correctness.
    ///   For example, pass public block armor when public only TCKey needs.
    ///
    /// - Parameters:
    ///   - armoredKey: PGP armor key
    ///   - passphrase: key passphrase
    static func key(from armoredKey: String, passphrase: String?) throws -> TCKey {
        do {
            guard let key = TCKey(armored: armoredKey), try key.goKeyRing?.getEncryptionKey() != nil else {
                throw TCError.pgpKeyError(reason: .invalidKeyFormat)
            }
            if let passphrase = passphrase {
                try key.unlock(passphrase: passphrase)
            }
            
            return key
        } catch DMSPGPError.invalidSecrectKeyPassword {
            throw TCError.pgpKeyError(reason: .invalidPassword)
        } catch let error as DMSPGPError {
            consolePrint(error.localizedDescription)
            throw TCError.pgpKeyError(reason: .invalidKeyFormat)
        } catch {
            if let goPGPError = DMGGoPGPError(from: error) {
                switch goPGPError {
                case .invalidSecrectKeyPassword:
                    throw TCError.pgpKeyError(reason: .invalidPassword)
                default:
                    throw TCError.pgpKeyError(reason: .invalidKeyFormat)
                }
            }
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
