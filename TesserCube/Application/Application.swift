//
//  Application.swift
//  TesserCube
//
//  Created by jk234ert on 2019/2/20.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import DMSOpenPGP
#if DEBUG
#if FLEX
import FLEX
#endif
#endif
import SwifterSwift
import IQKeyboardManagerSwift
import SVProgressHUD

class Application: NSObject {
    
    static let instance = Application()
    
    class func applicationConfigInit(_ application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        initLogger()
        initServices(application, launchOptions: launchOptions)
        
        initPersistentData()
        initUserDefaults()
        
        setupAppearance()
    }
    
    private class func initLogger() {
    }
    
    private class func initServices(_ application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {

        UIApplication.shared.applicationSupportsShakeToEdit = true

        if SwifterSwift.isInDebuggingMode || SwifterSwift.isInTestFlight {
            #if FLEX
            FLEXManager.shared().showExplorer()
            #endif
        } else {
            
        }

        IQKeyboardManager.shared.enable = true
    }
    
    private class func initPersistentData() {
//        TCDBManager.default?.test()
    }
    
    private class func initUserDefaults() {
        KeyboardPreference.accountName = "you get me!"

        DMSPGPArmoredHeader.commentHeaderContentForArmoredKey = "You can manage keys with https://tessercube.com"
        DMSPGPArmoredHeader.commentHeaderContentForMessage = "Encrypted with https://tessercube.com"
        
    }
    
    private class func setupAppearance() {
        SVProgressHUD.setHapticsEnabled(true)
//        UINavigationBar.appearance().barTintColor = .purple
//        UINavigationBar.appearance().tintColor = .white
//        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
//        UISearchBar.appearance().tintColor = .white
//        UISearchBar.appearance().barTintColor = .white
    }
}
