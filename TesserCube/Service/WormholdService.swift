//
//  WormholdService.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-5-8.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import MMWormhole

final class WormholdService {

    // MARK: - Singleton
    public static let shared = WormholdService()

    public let wormhole = MMWormhole(applicationGroupIdentifier: "group.com.sujitech.tessercube", optionalDirectory: "wormhole", transitingType: MMWormholeTransitingType.coordinatedFile)
    public let listeningWormhole = MMWormhole(applicationGroupIdentifier: "group.com.sujitech.tessercube", optionalDirectory: "wormhole", transitingType: MMWormholeTransitingType.coordinatedFile)
    private init() { }

    deinit {
        MessageIdentifier.allCases.forEach { id in
            listeningWormhole.stopListeningForMessage(withIdentifier: id.rawValue)
        }
    }

}

extension WormholdService {

    enum MessageIdentifier: String, CaseIterable {
        case appDidUpdateKeys
        case keyboardDidEncryptMessage
    }

}
