//
//  CreateKeyOption.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-5-23.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation

public enum CreateKeyOption {

    case ecc
    case rsa

    var displayName: String {
        switch self {
        case .ecc:
            return "EdDSA"
        case .rsa:
            return "RSA"
        }
    }

    var dmsPGPPublicKeyAlgorithm: KeyAlgorithm {
        switch self {
        case .ecc:
            return .x25519
        case .rsa:
            return .rsa
        }
    }

    var dmsSubkeyAlgorithm: KeyAlgorithm {
        switch self {
        case .ecc:
            return .x25519
        case .rsa:
            return .rsa
        }
    }

//    var curve: KeyCurve? {
//        switch self {
//        case .ecc:
//            return .Secp256k1
//        default:
//            return nil
//        }
//    }
}
