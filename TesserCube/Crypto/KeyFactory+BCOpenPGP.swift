//
//  KeyFactory+BCOpenPGP.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-4-26.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import DMSOpenPGP
import ConsolePrint

// MARK: - Decrypt
extension KeyFactory {

    struct DecryptResult {
        let message: String
        let signatureKey: TCKey?
        let recipientKeys: [TCKey]

        let verifyResult: DMSPGPSignatureVerifier.VerifyResult
        let unknownRecipientKeyIDs: [String]

    }

    static var keys: [TCKey] {
        return ProfileService.default.keys.value
    }

    /// Decrypt and verify the armored message & cleartext message.
    ///
    /// - Parameter armoredMessage: encrypted message
    /// - Returns: DecryptResult
//    static func decryptMessage(_ armoredMessage: String) throws -> DecryptResult {
//        // Message is cleartext signed message
//        // Do not need decrypt, just return the body and signature
//        // TODO: return signature
//        if DMSPGPClearTextVerifier.verify(armoredMessage: armoredMessage), let verifer = try? DMSPGPClearTextVerifier(cleartext: armoredMessage) {
//            let signatureVerifier = verifer.signatureVerifier
//            let (verifyResult, signatureKey) = signatureVerifier.verifySignature(use: keys)
//
//            return DecryptResult(message: verifer.message,
//                                 signatureKey: signatureKey,
//                                 recipientKeys: [],
//                                 verifyResult: verifyResult,
//                                 unknownRecipientKeyIDs: [])
//        }
//
//        do {
//            var message: String?
//            let armoredMessage = armoredMessage.trimmingCharacters(in: .whitespacesAndNewlines)
//            let decryptor = try DMSPGPDecryptor(armoredMessage: armoredMessage)
//
//            let encryptingKeyIDSet = Set(decryptor.encryptingKeyIDs)
//            var recipientKeys = keys
//                .filter { $0.hasSecretKey }
//                .filter { key in
//                    let decryptingKeyIDs: [String] =
//                        key.keyRing.secretKeyRing?.getDecryptingKeyIDs() ?? []
//                    let decryptingKeyIDSet = Set(decryptingKeyIDs)
//
//                    // should has common key if we want to decrypt it
//                    return !decryptingKeyIDSet.isDisjoint(with: encryptingKeyIDSet)
//            }
//            let unknownRecipientKeyIDs = Array(encryptingKeyIDSet.subtracting(recipientKeys.map { $0.keyID } ))
//
//            let hiddenRecipientIDCount = decryptor.hiddenRecipientsDataList.count
//
//            if hiddenRecipientIDCount > 0 {
//                var detectedRecipients = [TCKey]()
//                // 1. Filter out all keypairs with secret keys inside
//                let possibleKeys = keys
//                    .filter { $0.hasSecretKey }
//
//                // 2. Collect a keyID-password dict from KeyChain
//                var keyPasswordDict = [String: String]()
//                let possibleKeyIDs = possibleKeys.compactMap { $0.longIdentifier }
//
//                for keyChainItem in ProfileService.default.keyChain.allItems() {
//                    if let key = keyChainItem["key"] as? String, let password = keyChainItem["value"] as? String {
//                        if possibleKeyIDs.contains(key) {
//                            keyPasswordDict[key] = password
//                        }
//                    }
//                }
//
//                for hiddenRecipientEncryptedData in decryptor.hiddenRecipientsDataList {
//                    // For each hidden recipient encrypted data, check all possible keys to decrypt
//                    for possibleKey in possibleKeys {
//                        let possibleDecryptKeyIDs = possibleKey.keyRing.secretKeyRing?.getDecryptingKeyIDs() ?? []
//                        for perKeyID in possibleDecryptKeyIDs {
//                            if let privateKey = possibleKey.keyRing.secretKeyRing?.getDecryptingPrivateKey(keyID: perKeyID, password: keyPasswordDict[possibleKey.longIdentifier] ?? "") {
//                                do {
//                                    message = try decryptor.decrypt(privateKey: privateKey, encryptedData: hiddenRecipientEncryptedData)
//                                    detectedRecipients.append(possibleKey)
//                                } catch {
//                                    continue
//                                }
//                            }
//                        }
//                    }
//                }
//                recipientKeys.append(contentsOf: detectedRecipients)
//            }
//
//            if message == nil {
//                // Now we known all recipients. Use one available key to decryt
//                guard let decryptKey = recipientKeys.first,
//                    let password = try? ProfileService.default.keyChain.get(decryptKey.longIdentifier) else {
//                        throw TCError.pgpKeyError(reason: .noAvailableDecryptKey)
//                }
//
//                let decryptKeyIDs = decryptKey.keyRing.secretKeyRing?.getDecryptingKeyIDs() ?? []
//                guard let keyID = decryptor.encryptingKeyIDs.first(where: { decryptKeyIDs.contains($0) }),
//                    let privateKey = decryptKey.keyRing.secretKeyRing?.getDecryptingPrivateKey(keyID: keyID, password: password) else {
//                        assertionFailure()
//                        throw TCError.pgpKeyError(reason: .noAvailableDecryptKey)        // not found secret key to decrypt
//                }
//
//                message = try decryptor.decrypt(privateKey: privateKey, keyID: keyID)
//            }
//
//            guard let decryptedMessage = message else {
//                throw TCError.pgpKeyError(reason: .noAvailableDecryptKey)
//            }
//
//            let signatureVerifier = DMSPGPSignatureVerifier(message: decryptedMessage, onePassSignatureList: decryptor.onePassSignatureList, signatureList: decryptor.signatureList)
//            let (verifyResult, signatureKey) = signatureVerifier.verifySignature(use: keys)
//
//            // TODO: Display if there is any hidden recipients
//            return DecryptResult(message: decryptedMessage,
//                                 signatureKey: signatureKey,
//                                 recipientKeys: recipientKeys,
//                                 verifyResult: verifyResult,
//                                 unknownRecipientKeyIDs: unknownRecipientKeyIDs)
//        } catch {
//            throw error
//        }
//    }

}

fileprivate extension DMSPGPSignatureVerifier {

//    func verifySignature(use keys: [TCKey]) -> (VerifyResult, TCKey?)  {
//        let infos = signatureListKeyInfos
//        if infos.isEmpty {
//            return (.noSignature, nil)
//        }
//
//        let verifyKey = keys.first { key -> Bool in
//            return infos.contains(where: { $0.keyID == key.keyRing.publicKeyRing.primarySignatureKey?.keyID })
//        }
//
//        guard let key = verifyKey else {
//            return (.unknownSigner(infos), nil)
//        }
//
//        return (verifySignature(use: key.keyRing.publicKeyRing), key)
//    }

}

// MARK: - Clearsign & Encrypt
extension KeyFactory {

    /// Clearsign message
    ///
    /// - Parameters:
    ///   - message: raw message for sign
    ///   - signatureKey: signature key
    /// - Returns: cleartext formate message
    /// - Throws: invalid signature key or fail to retrieve password
//    static func clearsignMessage(_ message: String, signatureKey: TCKey) throws -> String {
//        guard signatureKey.hasPublicKey, signatureKey.hasSecretKey,
//        let secretKeyRing = signatureKey.keyRing.secretKeyRing else {
//            throw TCError.composeError(reason: .invalidSigner)
//        }
//
//        guard let password = try? ProfileService.default.keyChain
//            .authenticationPrompt("Unlock secret key to sign message")
//            .get(signatureKey.longIdentifier) else {
//            throw TCError.composeError(reason: .keychainUnlockFail)
//        }
//
//        do {
//            let signer = try DMSPGPSigner(secretKeyRing: secretKeyRing, password: password)
//            return signer.sign(message: message)
//        } catch {
//            consolePrint(error)
//            throw TCError.composeError(reason: .invalidSigner)
//        }
//    }

    /// Encrypt raw message to armored message. Create signnature if signatureKey not nil
    ///
    /// - Parameters:
    ///   - message: raw message for encrypt
    ///   - signatureKey: key for create signature
    ///   - recipients: recipients public key for encryption
    /// - Returns: armored encrypted message
    /// - Throws: empty recipients encrypt fail or sign fail (if signing)
    /// - Note: this method add signer to recipients when possible to prevent sender could not decrypt message
//    static func encryptMessage(_ message: String, signatureKey: TCKey?, recipients: [TCKey]) throws -> String {
//        guard !recipients.isEmpty else {
//            throw TCError.composeError(reason: .emptyRecipients)
//        }
//
//        // Get password for signature key
//        var signatureKeyPassword: String?
//        if let signatureKey = signatureKey {
//            guard signatureKey.hasPublicKey, signatureKey.hasSecretKey else {
//                throw TCError.composeError(reason: .invalidSigner)
//            }
//
//            guard let password = try? ProfileService.default.keyChain
//                .authenticationPrompt("Unlock secret key to sign message")
//                .get(signatureKey.longIdentifier) else {
//                throw TCError.composeError(reason: .keychainUnlockFail)
//            }
//            signatureKeyPassword = password
//        }
//
//        do {
//            var encryptor: DMSPGPEncryptor
//            // Add encryption key of signer if possible otherwise sender (a.k.a signer) could not decrypt message
//            if let secretKeyRing = signatureKey?.keyRing.secretKeyRing, let senderPublicKeyRing = signatureKey?.keyRing.publicKeyRing, let password = signatureKeyPassword {
//                let publicKeyDataList = recipients.map { DMSPGPEncryptor.PublicKeyData(publicKeyRing: $0.keyRing.publicKeyRing, isHidden: false)  } + [ DMSPGPEncryptor.PublicKeyData(publicKeyRing: senderPublicKeyRing, isHidden: false)]
//                encryptor = try DMSPGPEncryptor(publicKeyDataList: publicKeyDataList, secretKeyRing: secretKeyRing, password: password)
//            } else {
//                let publicKeyDataList = recipients.map { DMSPGPEncryptor.PublicKeyData(publicKeyRing: $0.keyRing.publicKeyRing, isHidden: false)  }
//                encryptor = try DMSPGPEncryptor(publicKeyDataList: publicKeyDataList)
//            }
//
//            let encrypted = try encryptor.encrypt(message: message)
//            return encrypted
//        } catch {
//            throw TCError.composeError(reason: .pgpError(error))
//        }
//
//    }

}
