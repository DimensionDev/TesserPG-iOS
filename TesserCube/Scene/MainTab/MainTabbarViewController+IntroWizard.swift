//
//  MainTabbarViewController+IntroWizard.swift
//  TesserCube
//
//  Created by jk234ert on 2019/6/17.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

private var guideTexts: [String] = {
    return [L10n.IntroWizardViewController.Step.contactsScene,
            L10n.IntroWizardViewController.Step.importContact,
            L10n.IntroWizardViewController.Step.messagesScene,
            L10n.IntroWizardViewController.Step.composeMessage,
            L10n.IntroWizardViewController.Step.interpretMessage,
            L10n.IntroWizardViewController.Step.meScene,
            L10n.IntroWizardViewController.Step.createKeyPair,
            L10n.IntroWizardViewController.Step.completeGuide]
}()

extension MainTabbarViewController: IntroWizardViewContorllerDelegate, IntroWizardViewControllerDataSource {
    
    func showIntroWizard() {
        let introWizardViewController = IntroWizardViewController()
        introWizardViewController.delegate = self
        introWizardViewController.dataSource = self
        present(introWizardViewController, animated: true)
    }
    
    // MARK: IntroWizardViewControllerDataSource
    func numberOfSteps(in viewController: IntroWizardViewController) -> Int {
        return guideTexts.count
    }
    
    func introWizardViewController(_ viewController: IntroWizardViewController, spotLightOfStepAt index: Int) -> IntroSpotlight? {
        // MARK: Simply use index to construct the introduction elements, for now
        switch index {
        case 0, 2, 5:
            var tabBarItemIndex = 0
            if index == 2 {
                tabBarItemIndex = 1
            }
            if index == 5 {
                tabBarItemIndex = 2
            }
            let spotlightFrame = getSpotlightFrameOfTabBarItem(index: tabBarItemIndex)
            return IntroSpotlight(rect: spotlightFrame, shape: .oval)
        case 1, 6:
            var screenFrame = view.bounds
            screenFrame = screenFrame.offsetBy(dx: 0, dy: UIApplication.shared.statusBarFrame.height - 10) // 10 is no-notch status bar height divided by 2
            let offset = CGPoint(x: -80, y: -19)
            let radius: CGFloat = 99.0 / 2.0
            let spotlightFrame = CGRect(x: screenFrame.origin.x + screenFrame.size.width + offset.x, y: screenFrame.origin.y + offset.y, width: radius * 2.0, height: radius * 2.0)
            return IntroSpotlight(rect: spotlightFrame, shape: .oval)
        case 3, 4:
            if let naviVC = viewControllers?[selectedIndex] as? UINavigationController, let messageVC = naviVC.viewControllers.first as? MessagesViewController {
                var buttonFrame = CGRect.zero
                if index == 3 {
                    buttonFrame = messageVC.getComposeButtonFrame()
                } else {
                    buttonFrame = messageVC.getInterpretButtonFrame()
                }
                let buttonFrameSpotlightFrame = getButtonSpotlightFrame(rect: buttonFrame, radius: CGSize(width: 111, height: 49))
                return IntroSpotlight(rect: buttonFrameSpotlightFrame, shape: .oval)
            }
            return nil
        default:
            return nil
        }
    }
    
    func introWizardViewController(_ viewController: IntroWizardViewController, arrowOfStepAt index: Int) -> IntroArrow? {
        guard let spotlight = introWizardViewController(viewController, spotLightOfStepAt: index) else {
            return nil
        }
        switch index {
        case 0, 2:
            let arrowFrame = CGRect(x: spotlight.rect.origin.x + 120, y: spotlight.rect.origin.y - 14, width: 58, height: 51)
            return IntroArrow(direction: .toBottomLeft, frame: arrowFrame)
        case 1, 6:
            let arrowFrame = CGRect(x: spotlight.rect.origin.x + 22, y: spotlight.rect.origin.y + 110, width: 37, height: 66)
            return IntroArrow(direction: .toTopRight, frame: arrowFrame)
        case 3:
            let arrowFrame = CGRect(x: spotlight.rect.origin.x + 240, y: spotlight.rect.origin.y + 9, width: 58, height: 51)
            return IntroArrow(direction: .toBottomLeft, frame: arrowFrame)
        case 4:
            let arrowFrame = CGRect(x: spotlight.rect.origin.x - 76, y: spotlight.rect.origin.y + 9, width: 58, height: 51)
            return IntroArrow(direction: .toBottomRight, frame: arrowFrame)
        case 5:
            let arrowFrame = CGRect(x: spotlight.rect.origin.x - 78, y: spotlight.rect.origin.y - 14, width: 58, height: 51)
            return IntroArrow(direction: .toBottomRight, frame: arrowFrame)
        default:
            return nil
        }
    }
    
    func introWizardViewController(_ viewController: IntroWizardViewController, guideTextAt index: Int) -> String? {
        return guideTexts[index]
    }
    
    // MARK: IntroWizardViewContorllerDelegate
    func introWizardViewController(_ viewController: IntroWizardViewController, willNavigateTo index: Int) {
        switch index {
        case 0:
            selectedIndex = 0
        case 2:
            selectedIndex = 1
        case 5:
            selectedIndex = 2
        default:
            break
        }
    }
    
    func createKeyButtonDidClicked(_ viewController: IntroWizardViewController) {
        if let naviVC = viewControllers?[selectedIndex] as? UINavigationController, let meVC = naviVC.viewControllers.first as? MeViewController {
            Coordinator.main.present(scene: .createKey, from: meVC, transition: .modal, completion: nil)
        }
    }
    
    func importKeyButtonDidClicked(_ viewController: IntroWizardViewController) {
        if let naviVC = viewControllers?[selectedIndex] as? UINavigationController, let meVC = naviVC.viewControllers.first as? MeViewController {
            Coordinator.main.present(scene: .importKey, from: meVC, transition: .modal, completion: nil)
        }
    }
    
    func introWizardViewController(_ viewController: IntroWizardViewController, willDismissAt index: Int) {
        Preference.isFirstTimeLaunch = false
    }
}

private extension MainTabbarViewController {
    func getSpotlightFrameOfTabBarItem(index: Int) -> CGRect {
        let barButton = tabBar.subviews[index + 1]
        let tabbarY = tabBar.frame.origin.y
        let barButtonFrameInWindow = barButton.frame.offsetBy(dx: 0, dy: tabbarY)
        let center = CGPoint(x: barButtonFrameInWindow.origin.x + barButtonFrameInWindow.size.width / 2.0, y: barButtonFrameInWindow.origin.y + barButtonFrameInWindow.size.height / 2.0)
        let radius: CGFloat = 99.0 / 2.0
        return CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2.0, height: radius * 2.0)
    }
    
    func getButtonSpotlightFrame(rect: CGRect, radius: CGSize) -> CGRect {
        let center = CGPoint(x: rect.origin.x + rect.size.width / 2.0, y: rect.origin.y + rect.size.height / 2.0)
        return CGRect(x: center.x - radius.width, y: center.y - radius.height, width: radius.width * 2.0, height: radius.height * 2.0)
    }
}
