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

extension TesserCubeUITests_Issue {
    
    // https://github.com/DimensionDev/Tessercube-iOS/issues/117
    func testIssue117() {
        // Reset application
        let _app = XCUIApplication()
        _app.launchArguments.append("ResetApplication")
        _app.launch()
        _app.terminate()

        skipWizard()
        
        importPublicKey_A_B()
        checkContactCount(2)
        importPublicKey_A_B_C()
        checkContactCount(3)
    }
    
}

extension TesserCubeUITests_Issue {
    
    // Skip wizard if needs
    func skipWizard() {
        let app = XCUIApplication()
        app.launch()
        
        if app.buttons["Skip Guides"].waitForExistence(timeout: 5.0) {
            app.buttons["Skip Guides"].tap()
        }
    }
    
    func importPublicKey_A_B() {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssert(app.tabBars.buttons["Contacts"].exists)
        app.tabBars.buttons["Contacts"].tap()
        
        // Prepare Key for A & B
        UIPasteboard.general.string = TesserCubeUITests_Issue.A_B
        
        // select bar button item "Add"
        let addButton = app.navigationBars.buttons["Add"].firstMatch
        XCTAssert(addButton.waitForExistence(timeout: 5.0))
        addButton.tap()
        
        // select button item "Import Keypair"
        let importButton = app.buttons["Import Keypair"].firstMatch
        XCTAssert(importButton.waitForExistence(timeout: 5.0))
        let importButtonIsEnabled = expectation(for: NSPredicate(format:"enabled == true"), evaluatedWith: importButton, handler: nil)
        wait(for: [importButtonIsEnabled], timeout: 5.0)
        importButton.tap()
        
        // check status is "Not Added Yet"
        let availableLabel = app.staticTexts["Not Added Yet"].firstMatch
        XCTAssert(availableLabel.waitForExistence(timeout: 5.0))
        
        // select bar button item "Add"
        let addContacttButton = app.buttons["Add Contact"].firstMatch
        XCTAssert(addContacttButton.waitForExistence(timeout: 5.0))
        addContacttButton.tap()
        
        // check status is "Not Added Yet"
        let availableLabel2 = app.staticTexts["Already Added"].firstMatch
        XCTAssert(availableLabel2.waitForExistence(timeout: 5.0))
    }
    
    func importPublicKey_A_B_C() {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssert(app.tabBars.buttons["Contacts"].exists)
        app.tabBars.buttons["Contacts"].tap()
        
        // Prepare Key for A & B & C
        UIPasteboard.general.string = TesserCubeUITests_Issue.A_B_C
        
        // select bar button item "Add"
        let addButton = app.navigationBars.buttons["Add"].firstMatch
        XCTAssert(addButton.waitForExistence(timeout: 5.0))
        addButton.tap()
        
        // select button item "Import Keypair"
        let importButton = app.buttons["Import Keypair"].firstMatch
        XCTAssert(importButton.waitForExistence(timeout: 5.0))
        let importButtonIsEnabled = expectation(for: NSPredicate(format:"enabled == true"), evaluatedWith: importButton, handler: nil)
        wait(for: [importButtonIsEnabled], timeout: 5.0)
        importButton.tap()
        
        // check status is "Not Added Yet"
        let availableLabel = app.staticTexts["One new key can be added"].firstMatch
        XCTAssert(availableLabel.waitForExistence(timeout: 5.0))
        
        // select bar button item "Add"
        let addContacttButton = app.buttons["Add Contact"].firstMatch
        XCTAssert(addContacttButton.waitForExistence(timeout: 5.0))
        addContacttButton.tap()
        
        // check status is "Not Added Yet"
        let availableLabel2 = app.staticTexts["Already Added"].firstMatch
        XCTAssert(availableLabel2.waitForExistence(timeout: 5.0))
    }
    
    func checkContactCount(_ count: Int) {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssert(app.tabBars.buttons["Contacts"].exists)
        app.tabBars.buttons["Contacts"].tap()
        
        XCTAssertEqual(app.tables.cells.count, count)
    }
    
}


extension TesserCubeUITests_Issue {
    
    /// stub public key from two key: A and B
    private static let A_B: String = """
-----BEGIN PGP PUBLIC KEY BLOCK-----

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
Nx4br2+JOkueZTaTR0lvv3s=
=erFA
-----END PGP PUBLIC KEY BLOCK-----
"""
    
    /// stub public key from two key: A and B
    private static let A_B_C: String = """
-----BEGIN PGP PUBLIC KEY BLOCK-----

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
ybmZ/eeZT89xgu7zJ9nC7XVLGvYp
=5cos
-----END PGP PUBLIC KEY BLOCK-----
"""
    
}
