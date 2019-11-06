//
//  WalletsViewController+Previews.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-6.
//  Copyright © 2019 Sujitech. All rights reserved.
//

#if canImport(SwiftUI) && DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct WalletsViewController_Preview: PreviewProvider {
    static var previews: some View {
        NavigationControllerRepresenable(rootViewController: WalletsViewController())
    }
}
#endif
