//
//  CryptoPublicKey.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-9-20.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import DMSGoPGP

extension CryptoPublicKey {

    public var algorithm: PublicKeyAlgorithm? {
        return PublicKeyAlgorithm(rawValue: getAlgorithm())
    }
    
}
