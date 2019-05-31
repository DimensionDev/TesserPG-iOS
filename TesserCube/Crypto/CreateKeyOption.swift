//
//  CreateKeyOption.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-5-23.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import DMSOpenPGP

public enum CreateKeyOption {

    case ecc
    case rsa

    var displayName: String {
        switch self {
        case .ecc:
            return "ECC(SECP256K1)"
        case .rsa:
            return "RSA"
        }
    }

    var dmsPGPPublicKeyAlgorithm: DMSPGPPublicKeyAlgorithm {
        switch self {
        case .ecc:
            return .ECDSA
        case .rsa:
            return .RSA_ENCRYPT
        }
    }

    var dmsSubkeyAlgorithm: DMSPGPPublicKeyAlgorithm {
        switch self {
        case .ecc:
            return .ELGAMAL_ENCRYPT
        case .rsa:
            return .RSA_ENCRYPT
        }
    }

    var curve: DMSPGPKeyCurve? {
        switch self {
        case .ecc:
            return .Secp256k1
        default:
            return nil
        }
    }
}
