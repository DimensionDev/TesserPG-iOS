//
//  HUD.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/25.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import SVProgressHUD

protocol HUDPresentable {
    func showHUD(_ message: String)
    func showHUD(_ message: String, modally: Bool)
    func showHUDInfo(_ message: String)
    func showHUDError(_ message: String)
    func showHUDSuccess(_ message: String)
    func hideHUD()
}

extension HUDPresentable where Self: UIView {
    
    func showHUD(_ message: String) {
        performOnMainQueue { [weak self] in
            SVProgressHUD.setContainerView(self)
            SVProgressHUD.setDefaultMaskType(.black)
            SVProgressHUD.show(withStatus: message)
        }
    }
    
    func showHUD(_ message: String, modally: Bool) {
        performOnMainQueue { [weak self] in
            SVProgressHUD.setContainerView(self)
            SVProgressHUD.setDefaultMaskType(modally ? .black : .none)
            SVProgressHUD.show(withStatus: message)
        }
    }
    
    func showHUDInfo(_ message: String) {
        performOnMainQueue { [weak self] in
            SVProgressHUD.setContainerView(self)
            SVProgressHUD.setDefaultMaskType(.none)
            SVProgressHUD.showInfo(withStatus: message)
        }
    }
    
    func showHUDError(_ message: String) {
        performOnMainQueue { [weak self] in
            SVProgressHUD.setContainerView(self)
            SVProgressHUD.setDefaultMaskType(.none)
            SVProgressHUD.showError(withStatus: message)
        }
    }
    
    func showHUDSuccess(_ message: String) {
        performOnMainQueue { [weak self] in
            SVProgressHUD.setContainerView(self)
            SVProgressHUD.setDefaultMaskType(.none)
            SVProgressHUD.showSuccess(withStatus: message)
        }
    }
    
    func hideHUD() {
        performOnMainQueue {
            SVProgressHUD.dismiss()
        }
    }
}

extension HUDPresentable where Self: UIViewController {
    func showHUD(_ message: String) {
        view.showHUD(message)
    }
    
    func showHUD(_ message: String, modally: Bool) {
        view.showHUD(message, modally: modally)
    }
    
    func showHUDInfo(_ message: String) {
        view.showHUDInfo(message)
    }
    
    func showHUDError(_ message: String) {
        view.showHUDError(message)
    }
    
    func showHUDSuccess(_ message: String) {
        view.showHUDSuccess(message)
    }
    
    func hideHUD() {
        view.hideHUD()
    }
}

extension UIView: HUDPresentable { }
extension UIViewController: HUDPresentable { }

func performOnMainQueue(_ block: @escaping () -> Void) {
    DispatchQueue.main.async(execute: block)
}

