//
//  TCErrors.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/24.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import DMSGoPGP

enum DMSPGPError: Error {
    case `internal`
    
    case notArmoredInput
    case invalidArmored
    
    case invalidKeyID
    case invalidCleartext
    case invalidMessage
    case invalidPublicKeyRing
    case invalidSecretKeyRing
    case invalidPrivateKey
    case invalidSecrectKeyPassword
    case invalidCurve
    case invalidKeyLength
    case notSupportAlgorithm(KeyAlgorithm)
    
    case missingEncryptionKey(keyRings: [CryptoKeyRing])
}


enum TCError: Error {
    
    enum PGPKeyErrorReason {
        case invalidPassword
        case invalidKeyFormat
        case messageNotSigned
        case failToExport
        case failToSave
        case failToGenerate
        case noAvailableDecryptKey
        
        var localizedDescription: String {
            switch self {
            case .invalidPassword:          return L10n.TCError.PGPKeyErrorReason.invalidPassword
            case .invalidKeyFormat:         return L10n.TCError.PGPKeyErrorReason.invalidKeyFormat
            case .messageNotSigned:         return L10n.TCError.PGPKeyErrorReason.messageNotSigned
            case .failToExport:             return L10n.TCError.PGPKeyErrorReason.failToExport
            case .failToSave:               return L10n.TCError.PGPKeyErrorReason.failToSave
            case .failToGenerate:           return L10n.TCError.PGPKeyErrorReason.failToGenerate
            case .noAvailableDecryptKey:    return L10n.TCError.PGPKeyErrorReason.noAvailableDecryptKey
            }
        }
    }

    enum ComposeErrorReason {
        case `internal`
        case emptyInput
        case emptySenderAndRecipients
        case invalidSigner
        case emptyRecipients
        case keychainUnlockFail
        case pgpError(Error)

        var localizedDescription: String {
            switch self {
            case .internal:                 return L10n.TCError.ComposeErrorReason.internal
            case .emptyInput:               return L10n.TCError.ComposeErrorReason.emptyInput
            case .emptySenderAndRecipients: return L10n.TCError.ComposeErrorReason.emptySenderAndRecipients
            case .invalidSigner:            return L10n.TCError.ComposeErrorReason.invalidSigner
            case .emptyRecipients:          return L10n.TCError.ComposeErrorReason.emptyRecipients
            case .keychainUnlockFail:       return L10n.TCError.ComposeErrorReason.keychainUnlockFail
            case .pgpError(let error):
                let nserror = (error as NSError)
                return L10n.TCError.ComposeErrorReason.pgpError(nserror.domain, "\(nserror.code)", nserror.localizedDescription)
            }
        }
    }
    
    enum InterpretErrorReason {
        case `internal`
        case emptyMessage
        case badPayload
        case keychianUnlockFailed
        case pgpError(Swift.Error)
        
        var localizedDescription: String {
            switch self {
            case .internal:                 return L10n.TCError.InterpretErrorReason.internal
            case .emptyMessage:             return L10n.TCError.InterpretErrorReason.emptyMessage
            case .badPayload:               return L10n.TCError.InterpretErrorReason.badPayload
            case .keychianUnlockFailed:     return L10n.TCError.InterpretErrorReason.keychianUnlockFailed
            case .pgpError(let error):
                let nserror = (error as NSError)
                return L10n.TCError.InterpretErrorReason.pgpError(nserror.domain, "\(nserror.code)", nserror.localizedDescription)
            }
        }
    }
    
    enum UserInfoErrorType {
        case invalidUserID(userID: String)
        
        var localizedDescription: String {
            switch self {
            case .invalidUserID(let userID):
                return L10n.TCError.UserInfoErrorType.invalidUserID(userID)
            }
        }
    }
    
    case pgpKeyError(reason: PGPKeyErrorReason)
    case userInfoError(type: UserInfoErrorType)
    case keysAlreadyExsit
    case composeError(reason: ComposeErrorReason)
    case interpretError(reason: InterpretErrorReason)
}

extension TCError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .pgpKeyError(let reason):
            return reason.localizedDescription
        case .userInfoError(let type):
            return type.localizedDescription
        case .keysAlreadyExsit:
            return L10n.TCError.keysAlreadyExsit
        case .composeError(reason: let reason):
            return reason.localizedDescription
        case .interpretError(let reason):
            return reason.localizedDescription
        }
    }
}
