//
//  ComposeActionViewController.swift
//  TesserCubeComposeAction
//
//  Created by Cirno MainasuK on 2019-7-19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import MobileCoreServices
import BouncyCastle_ObjC
import DMSOpenPGP
import ConsolePrint

import RxSwift
import RxCocoa

final class ComposeActionViewModel {

    // input
    var inputTexts: [String] = []
    let composedMessage = BehaviorRelay<Message?>(value: nil)

    // output
    let rawMessage = PublishRelay<String>()
    let messages: Driver<[Message]>

    init() {
        messages = composedMessage.asDriver()
            .map { [$0].compactMap { $0} }
            .asDriver()
    }

}

extension ComposeActionViewModel {

    func finalizeInput() {
        let message = inputTexts.joined(separator: "\n")
        rawMessage.accept(message)
    }

}

final class ComposeActionViewController: UIViewController {

    private let disposeBag = DisposeBag()
    private let viewModel = ComposeActionViewModel()

    private var didPresentComposeMessageViewController = false
    private lazy var messageCardViewController = MessageCardViewController()
    private lazy var composeMessageViewController: ComposeMessageViewController? = ComposeMessageViewController()

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

extension ComposeActionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.ComposeActionViewController.Title.composing
        view.backgroundColor = Asset.sceneBackground.color
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(ComposeActionViewController.doneBarButtonItemPressed(_:)))

        addChild(messageCardViewController)
        view.addSubview(messageCardViewController.view)
        messageCardViewController.didMove(toParent: self)
        messageCardViewController.viewModel.allowActions.accept([.copy])

        viewModel.rawMessage.asDriver(onErrorJustReturn: "")
            .drive(onNext: { [weak self] rawMessage in
                self?.composeMessageViewController?.messageTextView.text = rawMessage
            })
            .disposed(by: disposeBag)
        viewModel.messages.asDriver()
            .drive(messageCardViewController.viewModel.messages)
            .disposed(by: disposeBag)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard didPresentComposeMessageViewController else {
            present(UINavigationController(rootViewController: composeMessageViewController!), animated: false, completion: nil)
            didPresentComposeMessageViewController = true

            extractInputFromExtensionContext()
            NotificationCenter.default.addObserver(self, selector: #selector(ComposeActionViewController.extensionContextCompleteRequest(_:)), name: .extensionContextCompleteRequest, object: nil)
            return
        }
    }

}

extension ComposeActionViewController {

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

extension ComposeActionViewController {

    @objc private func extensionContextCompleteRequest(_ notification: Notification) {
        guard let _ = notification.object as? ComposeMessageViewController,
        let message = notification.userInfo?["message"] as? Message else {
            // User cancel compose or save draft
            self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
            return
        }

        title = L10n.ComposeActionViewController.Title.messageComposed
        composeMessageViewController = nil  // deinit
        messageCardViewController.viewModel.copyContentType = .armoredMessage
        messageCardViewController.viewModel.allowActions.accept([.copy])
        viewModel.composedMessage.accept(message)
    }

    @objc private func doneBarButtonItemPressed(_ sender: UIBarButtonItem) {
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }

}
