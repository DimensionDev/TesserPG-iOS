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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let editingRedPacketVC = EditingRedPacketViewController()
        editingRedPacketVC.optionsView = KeyboardModeManager.shared.optionsView
        
        addChild(editingRedPacketVC)
        view.addSubview(editingRedPacketVC.view)
        editingRedPacketVC.didMove(toParent: self)
        
        editingRedPacketVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            editingRedPacketVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            editingRedPacketVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            editingRedPacketVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            editingRedPacketVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}
