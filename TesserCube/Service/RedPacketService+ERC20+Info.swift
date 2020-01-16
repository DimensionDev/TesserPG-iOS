//
//  RedPacketService+ERC20Info.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-15.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import os
import Foundation
import RxSwift
import RxCocoa
import Web3

extension RedPacketService {
    
    enum ERC20 {
    
        static func name(for tokenAddress: String) -> Single<String> {
            // Init web3
            let web3 = WalletService.web3
            
            let erc20Contract: GenericERC20Contract
            do {
                let address = try EthereumAddress(hex: tokenAddress, eip55: false)
                erc20Contract = GenericERC20Contract(address: address, eth: web3.eth)
            } catch {
                return Single.error(error)
            }
            
            return Single.create { single -> Disposable in
                erc20Contract.name().call(block: .latest) { dict, error in
                    guard let name = dict?["_name"] as? String else {
                        single(.error(RedPacketService.Error.internal("cannot find ERC20 name for \(tokenAddress)")))
                        return
                    }
                    single(.success(name))
                }
                
                return Disposables.create { }
            }
        }
        
        static func symbol(for tokenAddress: String) -> Single<String> {
            // Init web3
            let web3 = WalletService.web3
            
            let erc20Contract: GenericERC20Contract
            do {
                let address = try EthereumAddress(hex: tokenAddress, eip55: false)
                erc20Contract = GenericERC20Contract(address: address, eth: web3.eth)
            } catch {
                return Single.error(error)
            }
            
            return Single.create { single -> Disposable in
                erc20Contract.symbol().call(block: .latest) { dict, error in
                    guard let symbol = dict?["_symbol"] as? String else {
                        single(.error(RedPacketService.Error.internal("cannot find ERC20 symbol for \(tokenAddress)")))
                        return
                    }
                    single(.success(symbol))
                }
                
                return Disposables.create { }
            }
        }
        
        static func decimals(for tokenAddress: String) -> Single<Int> {
            // Init web3
            let web3 = WalletService.web3
            
            let erc20Contract: GenericERC20Contract
            do {
                let address = try EthereumAddress(hex: tokenAddress, eip55: false)
                erc20Contract = GenericERC20Contract(address: address, eth: web3.eth)
            } catch {
                return Single.error(error)
            }
            
            return Single.create { single -> Disposable in
                erc20Contract.decimals().call(block: .latest) { dict, error in
                    guard let decimals = dict?["_decimals"] as? UInt8 else {
                        single(.error(RedPacketService.Error.internal("cannot find ERC20 decimals for \(tokenAddress)")))
                        return
                    }
                    single(.success(Int(decimals)))
                }
                
                return Disposables.create { }
            }
        }
        
    }
    
}
