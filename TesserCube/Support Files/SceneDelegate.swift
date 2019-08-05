//
//  SceneDelegate.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-8-5.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
            configure(window: window, with: userActivity)
        }

        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        window = UIWindow(windowScene: windowScene)
        window?.makeKeyAndVisible()
        Coordinator.main.present(scene: .main(message: nil, window: window!), from: nil)
    }

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        return scene.userActivity
    }
    
}

@available(iOS 13.0, *)
extension SceneDelegate {

    private func configure(window: UIWindow?, with userActivity: NSUserActivity) {

    }

}
