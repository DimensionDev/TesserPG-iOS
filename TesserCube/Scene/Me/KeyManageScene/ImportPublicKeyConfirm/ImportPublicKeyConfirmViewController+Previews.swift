//
//  ImportPublicKeyConfirmViewController+Previews.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-3-20.
//  Copyright © 2020 Sujitech. All rights reserved.
//

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ImportPublicKeyConfirmViewControllerRepresentable: UIViewControllerRepresentable {
    
    let tcKey: TCKey
    
    typealias UIViewControllerType = ImportPublicKeyConfirmViewController
    
    func makeUIViewController(context: Context) -> ImportPublicKeyConfirmViewController {
        return ImportPublicKeyConfirmViewController()
    }
    
    func updateUIViewController(_ importPublicKeyConfirmViewController: ImportPublicKeyConfirmViewController, context: Context) {
        let viewModel = ImportPublicKeyConfirmViewModel(tcKey: tcKey)
        importPublicKeyConfirmViewController.viewModel = viewModel
    }
    
}

@available(iOS 13.0, *)
struct ImportPublicKeyConfirmViewController_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            NavigationView {
                ImportPublicKeyConfirmViewControllerRepresentable(tcKey: PreviewStub.stubPublicTCKey_A_B)
                    .navigationBarTitle("New Contact")
            }
            .previewDisplayName("A + B")
        }
    }
    
}

#endif
