//
//  RedPacketPayloadEncryptor.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-23.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation

public protocol RedPacketPayloadEncryptor {
    func secPayload(from rawPayload: RedPacketRawPayLoad) throws -> String
}
