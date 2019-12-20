//
//  ModeSwitchHelper.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 12/17/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

enum TCKeyboardMode: CaseIterable {
    case encrypt
    case sign
    case redpacket
}

protocol TCkeyboardModeProvider: UIViewController {
    var mode: TCKeyboardMode { get }
    static var extraHeight: CGFloat { get }
}

class TCKeyboardModeSwitchHelper {
    
    static let modeProviderType: [TCKeyboardMode: TCkeyboardModeProvider.Type] =
        [.encrypt: EncryptViewController.self,
         .sign:  SignViewController.self,
         .redpacket:  RedPacketKeyboardViewController.self]
    
    class func createModeSwitchBarButtonItem(_ provider: TCkeyboardModeProvider) -> UIBarButtonItem {
        var title = "Mode: "
        switch provider.mode {
        case .encrypt:
            title += "Encrypt"
        case .sign:
            title += "Sign"
        case .redpacket:
            title += "Red Packet"
        }
        return UIBarButtonItem(title: title, style: .plain, target: self, action: nil)
    }
}
