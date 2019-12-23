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
    
    static func AES(for version: Int) -> AES? {
        assert(version == 1)
        
        let iv = GCM_IV
        let key = AES_KEY
        
        let gcm = GCM(iv: iv, mode: .combined)
        do {
            return try CryptoSwift.AES(key: key, blockMode: gcm, padding: .noPadding)
        } catch {
            os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            return nil
        }
    }
}

extension RedPacketService {
    
    struct WalletMeta {
        let walletAddress: EthereumAddress
        let walletPrivateKey: EthereumPrivateKey
    }
    
}
