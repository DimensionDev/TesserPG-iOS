//
//  MainTabbarViewController.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/18.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class MainTabbarViewController: UITabBarController {
    
    enum MainTabItem: CaseIterable {
        case contacts
        case messages
        case me
        
        var title: String? {
            switch self {
            case .contacts:
                return L10n.MainTabbarViewController.TabBarItem.Contacts.title
            case .messages:
                return L10n.MainTabbarViewController.TabBarItem.Messages.title
            case .me:
                return L10n.MainTabbarViewController.TabBarItem.Me.title
            }
        }
            
        var viewController: UIViewController {
            switch self {
            case .contacts:
                return ContactsListViewController()
            case .messages:
                return MessagesViewController()
            case .me:
                return MeViewController()
            }
        }
        
        var image: UIImage? {
            switch self {
            case .contacts:
                return Asset.mainTabContacts.image
            case .messages:
                return Asset.mainTabMessages.image
            case .me:
                return Asset.mainTabMe.image
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Preference.isFirstTimeLaunch {
            showIntroWizard()
        }
    }
    
    private func configUI() {
        // fix dark color under navigation bar during transition 
        view.backgroundColor = ._systemBackground
        
        tabBar.isTranslucent = true
        let tabViewControllers: [UIViewController] = MainTabItem.allCases.map {
            let vc = $0.viewController
            let naviVC = BaseNavigationController(rootViewController: vc)
            vc.title = $0.title
            naviVC.tabBarItem.title = vc.title
            naviVC.tabBarItem.image = $0.image

            return naviVC
        }
        
        setViewControllers(tabViewControllers, animated: false)
        selectedIndex = 1
    }
}
