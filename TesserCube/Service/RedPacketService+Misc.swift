//
//  RedPacketService+Misc.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import Foundation
import Web3
import CryptoSwift

extension RedPacketService {
    
    static func prepareWalletMeta(from walletModel: WalletModel) throws -> WalletMeta {
        let walletAddress = try EthereumAddress(hex: walletModel.address, eip55: false)
        let privateKeyHex = try walletModel.hdWallet.privateKey().key.toHexString()
        let walletPrivateKey = try EthereumPrivateKey(hexPrivateKey: "0x" + privateKeyHex)
        
        return WalletMeta(walletAddress: walletAddress,
                          walletPrivateKey: walletPrivateKey)
    }
    
    static func prepareContract(for contractAddressString: String, in web3: Web3, version: Int = 1) throws -> DynamicContract {
        // Only for contract v1
        assert(version == 1)
        let contractABIData = RedPacketService.redPacketContractABIData
        let contractAddress = try EthereumAddress(hex: contractAddressString, eip55: false)
        let contract = try web3.eth.Contract(json: contractABIData, abiKey: nil, address: contractAddress)
        
        return contract
    }
        
}

extension RedPacketService {
    
    static func armoredEncPayload(for redPacket: RedPacket) -> String? {
        guard let encPayload = redPacket.enc_payload?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return nil
        }
        
        guard !encPayload.isEmpty else {
            return nil
        }
        
        let hintText = "Claim this red packet with tessercube.com"
        
        return """
        ---Begin Smart Text---
        \(hintText)
        
        \(encPayload)
        ---End Smart Text---
        """
    }
    
    static func decryptResult(forArmoredEncPayload armoredEncPayload: String) throws -> EncPayloadDecryptResult {
        let armor = armoredEncPayload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !armor.isEmpty else {
            throw Error.checkAvailabilityFail
        }
        
        let scanner = Scanner(string: armor)
        scanner.charactersToBeSkipped = nil
        
        // Jump to cleartext signature begin
        scanner.scanUpTo("---Begin Smart Text---", into: nil)
        
        // Read ---Begin Smart Text---\r\n
        var smartTextHeader: NSString?
        scanner.scanUpToCharacters(from: .newlines, into: &smartTextHeader)
        scanner.scanCharacters(from: .newlines, into: nil)
        guard smartTextHeader == "---Begin Smart Text---" else {
            throw Error.openRedPacketFail("cannot read message header")
        }
        
        // Read armor headers
        var hintHeaders: [String] = []
        var nextLine: NSString? = ""
        var lastScanLocation: Int
        
        repeat {
            lastScanLocation = scanner.scanLocation
            scanner.scanUpToCharacters(from: .newlines, into: &nextLine)
            scanner.scanString("\r", into: nil)
            scanner.scanString("\n", into: nil)
            guard let hashHeader = nextLine else {
                throw DMSPGPError.invalidCleartext
            }
            nextLine = nil
            hintHeaders.append(hashHeader as String)
            
            if !scanner.scanUpToCharacters(from: .newlines, into: &nextLine) {
                // got one empty line
                // no more hash header
                break
            }
            
            if lastScanLocation == scanner.scanLocation {
                // scanner not move
                throw Error.openRedPacketFail("cannot read message armor")
            }
        } while lastScanLocation != scanner.scanLocation
        
        // Read one empty line
        scanner.scanString("\r", into: nil)
        scanner.scanString("\n", into: nil)
        
        // Read encPayload
        var encPayloadText: NSString?
        scanner.scanUpTo("---End Smart Text---", into: &encPayloadText)
        guard let encPayload = (encPayloadText as String?), !encPayload.isEmpty else {
            throw Error.openRedPacketFail("cannot read message payload")
        }
        
        let result = try Web3Secret.default.decryptResult(for: encPayload)
        return result
    }
    
}

public struct EncPayloadDecryptResult {
    let rawPayloadJSON: String
    let rawPayload: RedPacketRawPayLoad
    let encPayload: String  // no armor
}

extension RedPacketService {
    
    struct WalletMeta {
        let walletAddress: EthereumAddress
        let walletPrivateKey: EthereumPrivateKey
    }
    
}
