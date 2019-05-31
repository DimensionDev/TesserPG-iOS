//
//  SharePublicKeyActivity.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/24.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

// TODO: share PGP key via QR poster

//extension UIActivity.ActivityType {
//    static let sharePublicKey =
//        UIActivity.ActivityType("com.Sujitech.tessercube.sharePublicKey")
//}
//
//class SharePublicKeyActivity: UIActivity {
//
//    var keyData: Data?
//
//    override class var activityCategory: UIActivity.Category {
//        return .action
//    }
//
//    override var activityType: UIActivity.ActivityType? {
//        return .sharePublicKey
//    }
//
//    override var activityTitle: String? {
//        return "Generate Poster"
//    }
//
//    override var activityImage: UIImage? {
//        return UIImage(named: "mustachify-icon")
//    }
//
//    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
//        for case is String in activityItems {
//            return true
//        }
//
//        return false
//    }
//
//    override func prepare(withActivityItems activityItems: [Any]) {
//        for case let key as String in activityItems {
//            if let data = key.data(using: .utf8) {
//                keyData = data
//            }
//            return
//        }
//    }
//
//    override var activityViewController: UIViewController? {
//        return SharePosterViewController.createWithNavigation(activity: self)
//    }
//
//    override func perform() {
//        if let data = keyData {
//
//            activityDidFinish(true)
//        }
//        activityDidFinish(false)
//    }
//}
