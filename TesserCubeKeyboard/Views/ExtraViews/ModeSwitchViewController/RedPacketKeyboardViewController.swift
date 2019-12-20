//
//  RedPacketKeyboardViewController.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 12/19/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class RedPacketKeyboardViewController: UIViewController, TCkeyboardModeProvider {
    var mode: TCKeyboardMode {
        return .redpacket
    }
    
    static var extraHeight: CGFloat {
        return 240
    }
}
