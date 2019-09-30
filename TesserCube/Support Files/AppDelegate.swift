//
//  AppDelegate.swift
//  TesserCube
//
//  Created by jk234ert on 2019/2/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import GRDB
import ConsolePrint

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        #if XCTEST
        if ProcessInfo().arguments.contains("ResetApplication") {
            try? FileManager.default.removeItem(atPath: TCDBManager.dbFilePath)
        }
        #endif

        // Setup Application
        Application.applicationConfigInit(application, launchOptions: launchOptions)

        #if DEBUG
        consolePrint(TCDBManager.dbDirectoryUrl)
        consolePrint(TCDBManager.dbFilePath)
        #endif

        if #available(iOS 13, *) {
            // setup window in SceneDelegate
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)

            // Make it the key window first since navigator works by finding the key window
            window?.makeKeyAndVisible()
            Coordinator.main.present(scene: .main(message: nil, window: window!), from: nil)
        }

        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return Coordinator.main.handleUrl(app, open: url, options: options)
    }

}

@available(iOS 13.0, *)
extension AppDelegate {

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // info.plist: Default Configuration - SceneDelegate.swift
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {

    }

}

extension AppDelegate {

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .all
        }

        return .portrait
    }

}
