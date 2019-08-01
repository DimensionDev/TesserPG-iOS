//
//  TCBaseViewController.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit
import SafariServices

extension UIViewController {
    public func dch_checkDeallocation(afterDelay delay: TimeInterval = 2.0) {
        let rootParentViewController = dch_rootParentViewController
        
        if isMovingFromParent || rootParentViewController.isBeingDismissed {
            let disappearanceSource: String = isMovingFromParent ? "removed from its parent" : "dismissed"
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: { [weak self] in
                if let VC = self {
                    assert(self == nil, "\(VC.description) not deallocated after being \(disappearanceSource)")
                }
            })
        }
    }
    private var dch_rootParentViewController: UIViewController {
        var root = self
        while let parent = root.parent {
            root = parent
        }
        return root
    }
}

class CustomBackButton: UIButton {
    
    let titleLeftInset: CGFloat = 6.5
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configUI()
    }
    
    private func configUI() {
        let horizontal: CGFloat = titleLeftInset
        let vertical: CGFloat = 0.0
        titleEdgeInsets = UIEdgeInsets(top: vertical/2, left: horizontal/2, bottom: vertical/2, right: horizontal/2)
    }
    
    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let originRect = super.titleRect(forContentRect: contentRect)
        return CGRect(x: originRect.origin.x, y: originRect.origin.y, width: originRect.size.width + 20, height: originRect.size.height)
    }
    
//    override var intrinsicContentSize: CGSize {
//        let originSize = super.intrinsicContentSize
//        return CGSize(width: originSize.width + 20, height: originSize.height)
//    }
}

class TCBaseViewController: UIViewController {
    
    private static let reportIssueUrl = "https://github.com/DimensionDev/Tessercube-iOS/issues/new"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
        becomeFirstResponder()
    }
    
    func configUI() {
        if #available(iOS 13.0, *) {
            view.backgroundColor = .secondarySystemBackground
        } else {
            // Fallback on earlier versions
            view.backgroundColor = Asset.sceneBackground.color
        }
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == UIEvent.EventSubtype.motionShake {
            showReportFeedbackAlert()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        dch_checkDeallocation()
    }
    
//    @discardableResult
//    func addCustomBackButton() -> UIButton {
//        var backButtonTitle = "Back"
//        if let viewControllers = navigationController?.viewControllers, viewControllers.count >= 2 {
//            let previousVC = viewControllers[viewControllers.count - 2]
//            if let previousTitle = previousVC.title {
//                backButtonTitle = previousTitle
//            }
//        }
//        let backButton = CustomBackButton(type: .system)
//        backButton.addTarget(self, action: #selector(customBackButtonDidClicked(_:)), for: .touchUpInside)
//        backButton.setImage(Asset.backButton.image, for: .normal)
//        backButton.titleLabel?.font = FontFamily.SFProText.regular.font(size: 17)
//        backButton.setTitle(backButtonTitle, for: .normal)
////        backButton.titleEdgeInsets = UIEdgeInsets(horizontal: 6.5, vertical: 0)
//        view.addSubview(backButton)
//        backButton.snp.makeConstraints { maker in
//            maker.leading.equalToSuperview().offset(8)
//            maker.top.equalTo(view.safeAreaLayoutGuide)
//            maker.height.equalTo(44)
//        }
//        return backButton
//    }

//    @discardableResult
//    func addCustomRightBarButton(title: String?, target: Any, action: Selector) -> UIButton {
//        let button = UIButton(type: .system)
//        button.addTarget(target, action: action, for: .touchUpInside)
//        button.titleLabel?.font = FontFamily.SFProText.regular.font(size: 17)
//        button.setTitle(title, for: .normal)
//        view.addSubview(button)
//        button.snp.makeConstraints { maker in
//            maker.trailing.equalTo(view.layoutMarginsGuide)
//            maker.top.equalTo(view.safeAreaLayoutGuide)
//            maker.height.equalTo(44)
//        }
//        return button
//    }
//
//    @objc
//    private func customBackButtonDidClicked(_ sender: UIButton) {
//        navigationController?.popViewController(animated: true)
//    }
//
    func showReportFeedbackAlert() {
        // TODO: More configuration
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertVC.addAction(UIAlertAction(title: "Report Issue", style: .destructive, handler: { _ in
            let vc = SFSafariViewController(url: URL(string: TCBaseViewController.reportIssueUrl)!)
            self.present(vc, animated: true)
        }))
//        alertVC.addAction(UIAlertAction(title: "Send Feedback", style: .default, handler: { _ in
//            
//        }))
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        if let presenter = alertVC.popoverPresentationController {
            presenter.sourceView = view
            presenter.sourceRect = CGRect(origin: view.center, size: .zero)
            presenter.permittedArrowDirections = []
        }
        present(alertVC, animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension TCBaseViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
