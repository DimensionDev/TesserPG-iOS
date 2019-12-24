//
//  TCKeyboardModeContainer.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 12/18/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class TCKeyboardModeContainer {
    let containerView: UIView = UIView(frame: .zero)
    
    var topmostViewController: UIViewController?
    
    var modeSwitchView: ModeSwitchView?
    
    var mode: TCKeyboardMode = .encrypt
    
    init(mode: TCKeyboardMode) {
        
        switchModeView(to: mode)
    }
    
    func switchModeView(to mode: TCKeyboardMode) {
        topmostViewController?.view.removeFromSuperview()
        
        self.mode = mode
        let viewControllerType = TCKeyboardModeSwitchHelper.modeProviderType[mode]
        let modeViewController = viewControllerType!.init(nibName: nil, bundle: nil)
        
        let naviVC = createNavigationViewController(for: modeViewController)
        modeViewController.navigationItem.leftBarButtonItem = createModeSwitchBarButtonItem(modeViewController)
        containerView.addSubview(naviVC.view)
        
        topmostViewController = naviVC
        
        naviVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            naviVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            naviVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            naviVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            naviVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
    }
    
    private func createModeSwitchBarButtonItem(_ provider: TCkeyboardModeProvider) -> UIBarButtonItem {
        var title = "Mode: "
        switch provider.mode {
        case .encrypt:
            title += "Encrypt"
        case .sign:
            title += "Sign"
        case .redpacket:
            title += "Red Packet"
        }
        return UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(modeSwitchBarButtonDidClicked(_:)))
    }
    
    @objc
    private func modeSwitchBarButtonDidClicked(_ sender: UIBarButtonItem) {
        if modeSwitchView == nil {
            modeSwitchView = ModeSwitchView(frame: .zero)
            modeSwitchView?.delegate = self
            modeSwitchView?.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(modeSwitchView!)
            NSLayoutConstraint.activate([
                modeSwitchView!.topAnchor.constraint(equalTo: containerView.topAnchor),
                modeSwitchView!.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                modeSwitchView!.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                modeSwitchView!.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            ])
        } else {
            modeSwitchView?.removeFromSuperview()
            modeSwitchView = nil
        }
    }
    
    private func createNavigationViewController(for rootViewController: UIViewController) -> UINavigationController {
        let naviVC = UINavigationController(rootViewController: rootViewController)
        naviVC.navigationBar.isTranslucent = false
        naviVC.navigationBar.barTintColor = UIColor.keyboardBackgroundLight
        return naviVC
    }
}

extension TCKeyboardModeContainer: ModeSwitchViewDelegate {
    func modeSwitchView(_ modeSwitchView: ModeSwitchView, modeSwitchButtonDidClicked action: TCKeyboardMode) {
        self.modeSwitchView?.removeFromSuperview()
        self.modeSwitchView = nil
        if self.mode != action {
            switchModeView(to: action)
        }
    }
}
