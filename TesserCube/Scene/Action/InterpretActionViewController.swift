//
//  InterpretActionViewController.swift
//  TesserCubeInterpretAction
//
//  Created by Cirno MainasuK on 2019-7-16.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MobileCoreServices
import BouncyCastle_ObjC
import DMSOpenPGP
import ConsolePrint
import os

final class InterpretActionViewController: UIViewController {

    private let disposeBag = DisposeBag()

    private lazy var messageCardViewController = MessageCardViewController()
    private lazy var brokenMessageViewController = BrokenMessageViewController()

    let viewModel = InterpretActionViewModel()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        _init()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _init()
    }

    private func _init() {
        // Setup Bouncy Castle
        #if TARGET_IS_EXTENSION
        JavaSecuritySecurity.addProvider(with: OrgBouncycastleJceProviderBouncyCastleProvider())
        #endif
    }

}

extension InterpretActionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Asset.sceneBackground.color
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(InterpretActionViewController.doneBarButtonItemPressed(_:)))

        addChild(messageCardViewController)
        view.addSubview(messageCardViewController.view)
        messageCardViewController.didMove(toParent: self)

        messageCardViewController.viewModel.delegate = self

        viewModel.title.asDriver().drive(rx.title).disposed(by: disposeBag)
        viewModel.messages.asDriver()
            .drive(messageCardViewController.viewModel.messages)
            .disposed(by: disposeBag)
        viewModel.interpretedMessage.asDriver()
            .skip(1)
            .drive(onNext: { [weak self] message in
                guard let `self` = self else { return }
                let controller = self.brokenMessageViewController

                guard message == nil else {
                    if controller.parent != nil {
                        controller.willMove(toParent: nil)
                        controller.view.removeFromSuperview()
                        controller.removeFromParent()
                    }
                    return
                }

                if controller.parent == nil {
                    self.addChild(controller)
                    self.view.addSubview(controller.view)
                    controller.didMove(toParent: self)

                    controller.viewModel.message.accept(self.viewModel.inputTexts.joined(separator: "\n"))
                }
            })
            .disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        #if TARGET_IS_EXTENSION
        extractInputFromExtensionContext()
        NotificationCenter.default.addObserver(self, selector: #selector(InterpretActionViewController.extensionContextCompleteRequest(_:)), name: .extensionContextCompleteRequest, object: nil)
        #else
        // delay view model finalize to controller appear
        // prevent Touch ID & Face ID permission auth alert not display issue
        viewModel.finalizeInput()
        #endif
    }

}

extension InterpretActionViewController {

    #if TARGET_IS_EXTENSION
    private func extractInputFromExtensionContext() {
        // check input text
        let providers = extensionContext
            .flatMap { $0.inputItems as? [NSExtensionItem] }
            .flatMap { items in return items.compactMap { $0.attachments }.flatMap { $0 } } ?? []

        guard !providers.isEmpty else {
            assertionFailure()
            return
        }

        for (i, provider) in providers.enumerated() {
            consolePrint(provider)

            let typeIdentifier = kUTTypePlainText as String
            guard provider.hasItemConformingToTypeIdentifier(typeIdentifier) else { continue }

            //swiftlint:disable force_cast
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] text, error in
                guard let `self` = self else { return }
                guard error == nil else { return }
                switch text {
                case is String:
                    os_log("%{public}s[%{public}ld], %{public}s: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, text as! String)
                    let message = (text as? String) ?? ""
                    self.viewModel.inputTexts.append(message)

                case is URL:
                    os_log("%{public}s[%{public}ld], %{public}s: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, String(describing: text as! URL))
                    // Notes: ignore URL if pass in
                    // [ERROR] Failed to determine whether URL /var/mobile/Containers/Data/Application/78FFF5C0-FDEC-4E26-891B-E525885AD987/Documents/temporary/20190827-170106.txt (s) is managed by a file provider
                    // InterpretActionViewController.swift[133], extractInputFromExtensionContext(): file:///var/mobile/Containers/Data/Application/BBC162F1-AAF5-431A-AEA1-A1843C24C5C3/Documents/temporary/20190827-165641.txt
                default:
                    os_log("%{public}s[%{public}ld], %{public}s: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, String(describing: text))
                }

                if i == providers.count - 1 {
                    // notify viewModel done
                    DispatchQueue.main.async { [weak self] in
                        self?.viewModel.finalizeInput()
                    }
                }
            }
            //swiftlint:enable force_cast
        }   // end for … in …
    }
    #endif

}

extension InterpretActionViewController {

    #if TARGET_IS_EXTENSION
    @objc private func extensionContextCompleteRequest(_ notification: Notification) {
        guard let _ = notification.object as? ComposeMessageViewController,
        let message = notification.userInfo?["message"] as? Message else {
            return
        }

        messageCardViewController.viewModel.copyContentType = .armoredMessage
        messageCardViewController.viewModel.allowActions.accept([.copy])
        viewModel.composedMessage.accept(message)
    }
    #endif

    @objc private func doneBarButtonItemPressed(_ sender: UIBarButtonItem) {
        #if TARGET_IS_EXTENSION
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
        #else
        dismiss(animated: true, completion: nil)
        #endif
    }

}

// MARK: - InterpretActionViewModelDelegate
extension InterpretActionViewController: MessageCardViewModelDelegate {

    func writeReply(to recipients: [KeyBridge], from sender: KeyBridge?) {
        let controller = ComposeMessageViewController()
        controller.viewModel.keyBridges.accept(recipients)
        controller.viewModel.senderKeyBridge = sender
        present(UINavigationController(rootViewController: controller), animated: true, completion: nil)
    }

}