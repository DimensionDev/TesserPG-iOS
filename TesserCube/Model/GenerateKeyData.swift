//
//  GenerateKeyData.swift
//  TesserCube
//
//  Created by jk234ert on 8/28/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation

//public enum KeyCurve {
//    case NIST_P256
//    case NIST_P384
//    case NIST_P521
//    case Secp256k1
//
//    public var parameterSpecName: String {
//        switch self {
//        case .NIST_P256:
//            return "P-256"
//        case .NIST_P384:
//            return "P-384"
//        case .NIST_P521:
//            return "P-521"
//        case .Secp256k1:
//            return "secp256k1"
//        }
//    }
//}

public enum KeyAlgorithm: String {
    case rsa
    case x25519
}

// PublicKeyAlgorithm uint8
// Ref: crypto/openpgp/packet/packet.go
public enum PublicKeyAlgorithm: Int, CaseIterable {
    case RSA     = 1
    case Elgamal = 16
    case DSA     = 17

    case ECDH    = 18
    case ECDSA   = 19

    case EdDSA   = 22

    case RSA_Encrypt = 2
    case RSA_Sign    = 3
}

extension PublicKeyAlgorithm {
    public var displayName: String {
        switch self {
        case .RSA,
             .RSA_Encrypt,
             .RSA_Sign:
            return "RSA"
        case .Elgamal:
            return "Elgamal"
        case .DSA:
            return "DSA"
        case .ECDH:
            return "EC"
        case .ECDSA:
            return "ECDSA"
        case .EdDSA:
            return "EdDSA"
        }
    }
}

public struct KeyData {
    public var strength: Int = 3072
    public var algorithm: KeyAlgorithm = .rsa
    // public var curve: KeyCurve?
    
    public init(strength: Int = 3072, algorithm: KeyAlgorithm = .rsa) {
        self.strength = strength
        self.algorithm = algorithm
        // self.curve = curve
    }
}

public struct GenerateKeyData {
    public var name: String
    public var email: String
    public var password: String
    public var masterKey: KeyData
    public var subkey: KeyData
    
    public init(name: String, email: String, password: String?, masterKey: KeyData, subkey: KeyData) {
        self.name = name
        self.email = email
        self.password = password ?? ""
        self.masterKey = masterKey
        self.subkey = subkey
    }
}
