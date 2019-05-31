//
//  FloatingAction.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/24.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

public final class FloatingAction {
    
    // MARK: Public
    
    public private(set) var title: String?
    public var tintColor: UIColor?
    public var textColor: UIColor?
    public var font: UIFont?
    
    public init(title: String, handleImmediately: Bool = false, handler: ((FloatingAction) -> Void)?) {
        self.title = title
        self.handleImmediately = handleImmediately
        self.handler = handler
    }
    
    // MARK: Internal
    
    private(set) var handler: ((FloatingAction) -> Void)?
    private(set) var handleImmediately = false
}

