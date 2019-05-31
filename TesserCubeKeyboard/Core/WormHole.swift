//
//  WormHole.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/4/5.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

extension UIApplication {
    
    public static func sharedApplication() -> UIApplication {
        guard UIApplication.responds(to: Selector("sharedApplication")) else {
            fatalError("UIApplication.sharedKeyboardApplication(): `UIApplication` does not respond to selector `sharedApplication`.")
        }
        
        guard let unmanagedSharedApplication = UIApplication.perform(Selector("sharedApplication")) else {
            fatalError("UIApplication.sharedKeyboardApplication(): `UIApplication.sharedApplication()` returned `nil`.")
        }
        
        guard let sharedApplication = unmanagedSharedApplication.takeUnretainedValue() as? UIApplication else {
            fatalError("UIApplication.sharedKeyboardApplication(): `UIApplication.sharedApplication()` returned not `UIApplication` instance.")
        }
        
        return sharedApplication
    }
    
    public func openContainerAppForFullAccess() {
        let url = URL(string: "tessercube://fullAccess")!
        self.perform(Selector("openURL:"), with: url)
    }
    
}
