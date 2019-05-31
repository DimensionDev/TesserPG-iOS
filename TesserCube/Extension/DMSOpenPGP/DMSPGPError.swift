//
//  DMSPGPError.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-5-31.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import DMSOpenPGP

extension DMSPGPError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .internal:                     return L10n.DMSPGPError.internal
        case .notArmoredInput:              return L10n.DMSPGPError.notArmoredInput
        case .invalidArmored:               return L10n.DMSPGPError.invalidArmored
        case .invalidKeyID:                 return L10n.DMSPGPError.invalidKeyID
        case .invalidCleartext:             return L10n.DMSPGPError.invalidCleartext
        case .invalidMessage:               return L10n.DMSPGPError.invalidMessage
        case .invalidPublicKeyRing:         return L10n.DMSPGPError.invalidPublicKeyRing
        case .invalidSecretKeyRing:         return L10n.DMSPGPError.invalidSecretKeyRing
        case .invalidPrivateKey:            return L10n.DMSPGPError.invalidPrivateKey
        case .invalidSecrectKeyPassword:    return L10n.DMSPGPError.invalidSecrectKeyPassword
        case .invalidCurve:                 return L10n.DMSPGPError.invalidCurve
        case .invalidKeyLength:             return L10n.DMSPGPError.invalidKeyLength
        case .notSupportAlgorithm(let algorithm):
            return L10n.DMSPGPError.notSupportAlgorithm(algorithm.displayName)
        case .missingEncryptionKey(let keyRings):
            let fingerprints = keyRings.map { $0.primaryKey.fingerprint }.joined(separator: ", ")
            return L10n.DMSPGPError.missingEncryptionKey(fingerprints)
        }
    }
}
