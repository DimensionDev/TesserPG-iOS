//
//  AppDelegate.swift
//  TesserCube
//
//  Created by jk234ert on 2019/2/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import BouncyCastle_ObjC
import ConsolePrint

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Setup Bouncy Castle
        JavaSecuritySecurity.addProvider(with: OrgBouncycastleJceProviderBouncyCastleProvider())

//        #if DEBUG
//        let realm = WordSuggestionService.shared.realm
//        realm.beginWrite()
//        realm.deleteAll()
//        try? realm.commitWrite()
//        #endif

        let wordPredictor = WordSuggestionService.shared.wordPredictor
        if wordPredictor.needLoadNgramData {
            wordPredictor.load { error in
                consolePrint(error?.localizedDescription ?? "NGram realm setup success")
            }
        }

        #if DEBUG
        if AppDelegate.isRunningTests {
            window?.rootViewController = UIViewController()
            return true
        }

        consolePrint(TCDBManager.dbDirectoryUrl)
        consolePrint(TCDBManager.dbFilePath)
        #endif

        Application.applicationConfigInit(application, launchOptions: launchOptions)
        window = UIWindow(frame: UIScreen.main.bounds)
        
        //Make it the keywindow first since navigator works by finding the keywindow
        window?.makeKeyAndVisible()
        Coordinator.main.present(scene: .main(message: nil), from: nil)

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return Coordinator.main.handleUrl(app, open: url, options: options)
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

extension AppDelegate {

    static var isRunningTests: Bool {
        return ProcessInfo().environment["XCInjectBundleInto"] != nil
    }

}
