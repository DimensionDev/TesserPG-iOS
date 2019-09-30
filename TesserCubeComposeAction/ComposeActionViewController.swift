//
//  ComposeActionViewController.swift
//  TesserCubeComposeAction
//
//  Created by Cirno MainasuK on 2019-7-19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import MobileCoreServices
import ConsolePrint
import RxSwift
import RxCocoa
import os

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
}

extension ComposeActionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.ComposeActionViewController.Title.composing
        view.backgroundColor = ._systemBackground
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
            let navigationController = UINavigationController(rootViewController: composeMessageViewController!)
            navigationController.modalPresentationStyle = .currentContext
            present(navigationController, animated: false, completion: nil)
            didPresentComposeMessageViewController = true

            extractInputFromExtensionContext()
            NotificationCenter.default.addObserver(self, selector: #selector(ComposeActionViewController.extensionContextCompleteRequest(_:)), name: .messageComposeComplete, object: nil)
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
