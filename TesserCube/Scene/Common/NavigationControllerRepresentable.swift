//
//  NavigationControllerRepresentable.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-6.
//  Copyright © 2019 Sujitech. All rights reserved.
//

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct NavigationControllerRepresenable<T: UIViewController>: UIViewControllerRepresentable {

    var rootViewController: T

    func makeUIViewController(context: Context) -> UINavigationController {
        return UINavigationController(rootViewController: rootViewController)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {

    }

}

#endif
