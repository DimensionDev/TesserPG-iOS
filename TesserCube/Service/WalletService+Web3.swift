//
//  WalletService+Web3.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-13.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import os
import RxSwift
import Web3

extension WalletService {

    public static func getBalance(for address: String) -> Single<BigUInt> {
        return Single.create { single in
            do {
                let ethereumAddress = try EthereumAddress(hex: address, eip55: false)   // should EIP55 but compatibility first
                web3.eth.getBalance(address: ethereumAddress, block: .latest) { response in
                    switch response.status {
                    case .success(let result): single(.success(result.quantity))
                    case .failure(let error):  single(.error(error))
                    }
                }
            } catch {
                os_log("%{public}s[%{public}ld], %{public}s: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)

                single(.error(error))
            }

            return Disposables.create { }
        }
    }

}
