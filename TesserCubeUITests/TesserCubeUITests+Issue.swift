//
//  TesserCubeUITests+Issue.swift
//  TesserCubeUITests
//
//  Created by Cirno MainasuK on 2020-3-20.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import XCTest

class TesserCubeUITests_Issue: XCTestCase {
    
    override func setUp() {
        continueAfterFailure = false
    }
    
    override func tearDown() {
        let app = XCUIApplication()
        print(app.debugDescription)
    }
    
    func testSmoke() {
        let app = XCUIApplication()
        app.launch()
    }
    
    func testResetApplication() {
        let app = XCUIApplication()
        app.launchArguments.append("ResetApplication")
        app.launch()
    }
    
}
