//
//  KeyboardModeManager+RedPacket.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 11/5/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

extension KeyboardModeManager {
    func addEditingRedPacketView() {
        if editingRedPacketViewControllerNaviVC == nil {
            let editingRedPacketView = EditingRedPacketViewController(nibName: "EditingRedPacketViewController", bundle: nil)
            editingRedPacketView.optionsView = optionsView
            editingRedPacketViewControllerNaviVC = UINavigationController(rootViewController: editingRedPacketView)
//            editingRedPacketView?.updateColor(theme: currentTheme)
//            editingRedPacketView?.delegate = self
//            editingRedPacketView?.optionFieldView = optionsView
            keyboardVC?.addChild(editingRedPacketViewControllerNaviVC!)
            keyboardVC?.view.insertSubview(editingRedPacketViewControllerNaviVC!.view, belowSubview: optionsView)
            editingRedPacketViewControllerNaviVC?.didMove(toParent: keyboardVC)
            
            editingRedPacketViewControllerNaviVC?.view.snp.makeConstraints{ make in
                make.leading.trailing.top.equalToSuperview()
                make.height.equalTo(metrics[.redPacketBanner]!)
            }
        }
    }
    
    func removeEditingRedPacketView() {
        if editingRedPacketViewControllerNaviVC != nil {
            editingRedPacketViewControllerNaviVC?.willMove(toParent: nil)
            editingRedPacketViewControllerNaviVC?.view.removeFromSuperview()
            editingRedPacketViewControllerNaviVC?.removeFromParent()
            editingRedPacketViewControllerNaviVC = nil
        }
    }
}
