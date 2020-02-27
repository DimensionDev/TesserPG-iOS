//
//  MessageService.swift
//  TesserCube
//
//  Created by MainasuK Cirno on 2020/2/25.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import Foundation

class MessageService {
 
    public static let shared = MessageService()
    
    private init() { }
    
}

extension MessageService {
    
    // OpenPGP armor
    // ref: https://tools.ietf.org/html/rfc4880#section-6.2
    private enum MessageArmor: String {
        // encrypted message
        case messageHeader = "-----BEGIN PGP MESSAGE-----"
        case messageFooter = "-----END PGP MESSAGE-----"
        
        // cleartext meesage
        case signedMessageHeader = "-----BEGIN PGP SIGNED MESSAGE-----"
        case signatureMessageHeader = "-----BEGIN PGP SIGNATURE-----"
        case signatureMessageFooter = "-----END PGP SIGNATURE-----"
    }
}

extension MessageService {
    
    public static func extractMessageBlock(from armored: String) -> String? {
        // encrypted message
        if let header = armored.range(of: MessageArmor.messageHeader.rawValue),
        let footer = armored.range(of: MessageArmor.messageFooter.rawValue) {
            return String(armored[header.lowerBound..<footer.upperBound])
        }
        
        // cleartext message
        if let header = armored.range(of: MessageArmor.signedMessageHeader.rawValue),
        let footer = armored.range(of: MessageArmor.signatureMessageFooter.rawValue) {
            return String(armored[header.lowerBound..<footer.upperBound])
        }
        
        return nil
    }
    
}
