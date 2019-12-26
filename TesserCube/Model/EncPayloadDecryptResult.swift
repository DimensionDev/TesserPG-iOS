//
//  EncPayloadDecryptResult.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-26.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation

public struct EncPayloadDecryptResult {
    let rawPayloadJSON: String
    let rawPayload: RedPacketRawPayLoad
    let encPayload: String  // no armor
}
