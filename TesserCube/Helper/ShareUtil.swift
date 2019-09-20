//
//  ShareUtil.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/24.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class ShareUtil {

    // share public key
    static func share(key: TCKey, from viewController: UIViewController, over view: UIView?) {
        let armoredKeyString = key.publicArmored
        let items: [Any] = [armoredKeyString]

        let vc = UIActivityViewController(activityItems: items, applicationActivities: [])
        vc.completionWithItemsHandler = { type, result, items, error in
            // do nothing
        }

        if let presenter = vc.popoverPresentationController {
            if let view = view {
                presenter.sourceView = view
                presenter.sourceRect = view.bounds
            } else {
                presenter.sourceView = viewController.view
                presenter.sourceRect = CGRect(origin: viewController.view.center, size: .zero)
                presenter.permittedArrowDirections = []
            }
        }
        viewController.present(vc, animated: true)
    }

    static func export(key: TCKey, from viewController: UIViewController, over view: UIView?) {
        let passwordDict = ProfileService.default.getPasswordDict(keyIdentifiers: [key.longIdentifier])
        let privateArmored = try? key.getPrivateArmored(passprahse: passwordDict[key.longIdentifier]) ?? ""
        let armoredKeyString = [key.publicArmored, privateArmored].compactMap { $0 }.joined(separator: "\n")

        var items: [Any] = []
        if let armoredKeyFileURL = createTempFile(for: armoredKeyString) {
            items.append(armoredKeyFileURL)
        } else {
            items.append(armoredKeyString)
        }

        let vc = UIActivityViewController(activityItems: items, applicationActivities: [])
        vc.completionWithItemsHandler = { type, result, items, error in
            // do nothing
        }

        if let presenter = vc.popoverPresentationController {
            if let view = view {
                presenter.sourceView = view
                presenter.sourceRect = view.bounds
            } else {
                presenter.sourceView = viewController.view
                presenter.sourceRect = CGRect(origin: viewController.view.center, size: .zero)
                presenter.permittedArrowDirections = []
            }
        }
        viewController.present(vc, animated: true)
    }
    
    static func share(message: String, from viewController: UIViewController, over view: UIView?) {
        let items: [Any] = [message]

        let vc = UIActivityViewController(activityItems: items, applicationActivities: [])
        vc.completionWithItemsHandler = { type, result, items, error in
            // do nothing
        }

        if let presenter = vc.popoverPresentationController {
            if let view = view {
                presenter.sourceView = view
                presenter.sourceRect = view.bounds
            } else {
                presenter.sourceView = viewController.view
                presenter.sourceRect = CGRect(origin: viewController.view.center, size: .zero)
                presenter.permittedArrowDirections = []
            }
        }
        viewController.present(vc, animated: true)
    }

}

extension ShareUtil {

    static func createTempFile(for text: String) -> NSURL? {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let filename: String = {
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd-HHmmss"
            return formatter.string(from: now)
        }()
        let fileURL = temporaryDirectory.appendingPathComponent(filename + ".txt")
        do {
            try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true, attributes: nil)
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL as NSURL
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }

}
