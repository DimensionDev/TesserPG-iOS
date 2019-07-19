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

final class InterpretActionViewController: UIViewController {

    private let disposeBag = DisposeBag()

    private lazy var messageCardViewController = MessageCardViewController()
    private lazy var brokenMessageViewController = BrokenMessageViewController()

    private let viewModel = InterpretActionViewModel()

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
        JavaSecuritySecurity.addProvider(with: OrgBouncycastleJceProviderBouncyCastleProvider())
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

                    controller.messageLabel.text = self.viewModel.inputTexts.joined(separator: "\n")
                }
            })
            .disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        extractInputFromExtensionContext()
        NotificationCenter.default.addObserver(self, selector: #selector(InterpretActionViewController.extensionContextCompleteRequest(_:)), name: .extensionContextCompleteRequest, object: nil)
    }

}

extension InterpretActionViewController {

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

            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] text, error in
                guard let `self` = self else { return }
                guard error == nil else { return }
                guard let text = text as? String else { return }

                self.viewModel.inputTexts.append(text)

                if i == providers.count - 1 {
                    // notify viewModel done
                    DispatchQueue.main.async { [weak self] in
                        self?.viewModel.finalizeInput()
                    }
                }
            }
        }   // end for … in …
    }

}

extension InterpretActionViewController {

    @objc private func extensionContextCompleteRequest(_ notification: Notification) {
        guard let _ = notification.object as? ComposeMessageViewController,
        let message = notification.userInfo?["message"] as? Message else {
            return
        }

        messageCardViewController.viewModel.copyContentType = .armoredMessage
        messageCardViewController.viewModel.allowActions.accept([.copy])
        viewModel.composedMessage.accept(message)
    }

    @objc private func doneBarButtonItemPressed(_ sender: UIBarButtonItem) {
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
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
