//
//  TesserCubeUITests.swift
//  TesserCubeUITests
//
//  Created by jk234ert on 2019/2/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import XCTest

class TesserCubeUITests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
//        let app = XCUIApplication()
//        print(app.debugDescription)
    }

    func test() {
        //createKey(name: "Alice", email: "alice@pgp.org", password: "Alice")
        //
        //let alicePrivateKeyArmor = copyPrivateKey(name: "Alice")
        //print(alicePrivateKeyArmor)
        //
        //let bobPrivateKeyArmor = copyPrivateKey(name: "Bob")
        //print(bobPrivateKeyArmor)
    }

    func testKeyCreateAndRemove() {
        skipWizard()
        checkExist(name: "Bob", isExist: false)
        createKey(name: "Bob", email: "bob@pgp.org", password: "Bob")
        checkExist(name: "Bob", isExist: true)
        deleteKey(name: "Bob")
        checkExist(name: "Bob", isExist: false)
    }

    func skipWizard() {
        let app = XCUIApplication()
        app.launch()

        if app.buttons["Skip Guides"].exists {
            app.buttons["Skip Guides"].tap()
        }
    }

    // create private key by name
    func createKey(name: String, email: String, password: String) {
        let app = XCUIApplication()
        app.launch()

        // Move to "Me" tab
        XCTAssert(app.navigationBars["Messages"].exists)
        XCTAssert(app.tabBars.buttons.count == 3)
        XCTAssert(app.tabBars.buttons["Me"].exists)
        app.tabBars.buttons["Me"].tap()

        // Not exists
        guard !app.tables.cells.staticTexts[name].exists else {
            return
        }

        // Tap "+" bar button item
        XCTAssert(app.navigationBars.buttons["Add"].exists)
        app.navigationBars.buttons["Add"].tap()

        // Tap "Create Keypair" action
        XCTAssert(app.sheets.buttons["Create Keypair"].exists)
        app.sheets.buttons["Create Keypair"].tap()

        // Fill form to create key
        XCTAssert(app.tables.textFields["Name"].waitForExistence(timeout: 3.0))
        XCTAssert(app.tables.textFields["Name"].exists)
        XCTAssert(app.tables.textFields["Email"].exists)
        XCTAssert(app.tables.secureTextFields["Password"].exists)
        XCTAssert(app.tables.secureTextFields["Confirm Password"].exists)

        app.tables.textFields["Name"].tap()
        app.tables.textFields["Name"].typeText(name)
        app.tables.textFields["Email"].tap()
        app.tables.textFields["Email"].typeText(email)
        app.tables.secureTextFields["Password"].tap()
        app.tables.secureTextFields["Password"].typeText(password)
        app.tables.secureTextFields["Confirm Password"].tap()
        app.tables.secureTextFields["Confirm Password"].typeText(password)

        // Confirm create
        XCTAssert(app.tables.buttons["Create Keypair"].exists)
        app.tables.buttons["Create Keypair"].tap()

        XCTAssert(app.tables.cells.staticTexts[name].waitForExistence(timeout: 10))
    }

    // copy private key by name
    func copyPrivateKey(name: String) -> String {
        let app = XCUIApplication()
        app.launch()

        // Move to "Me" tab
        XCTAssert(app.navigationBars["Messages"].exists)
        XCTAssert(app.tabBars.buttons.count == 3)
        XCTAssert(app.tabBars.buttons["Me"].exists)
        app.tabBars.buttons["Me"].tap()

        // Check name exists
        let card = app.tables.cells.containing(.staticText, identifier: name).firstMatch
        XCTAssert(card.exists)

        // Copy
        card.tap()
        XCTAssert(app.sheets.buttons["Export Private Key"].exists)
        app.sheets.buttons["Export Private Key"].tap()

        // Wait 5s
        let sleep = expectation(description: "Sleep")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            sleep.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)

        // Tap Copy
        print(app.collectionViews.cells.firstMatch.exists)
        app.collectionViews.cells.firstMatch.tap()

        // Tap close button
        // app.navigationBars.element(boundBy: 1).children(matching: .button).firstMatch.tap()

        // Tap remainder. Crash
        // app.collectionViews.scrollViews.cells.element(boundBy: 0).tap()

        return UIPasteboard.general.string!
    }

    // delete private key by name
    func deleteKey(name: String) {
        let app = XCUIApplication()
        app.launch()

        // Move to "Me" tab
        XCTAssert(app.navigationBars["Messages"].exists)
        XCTAssert(app.tabBars.buttons.count == 3)
        XCTAssert(app.tabBars.buttons["Me"].exists)
        app.tabBars.buttons["Me"].tap()

        let card = app.tables.cells.containing(.staticText, identifier: name).firstMatch
        XCTAssert(card.exists)
        card.tap()

        // Tap "Create Keypair" action
        XCTAssert(app.sheets.buttons["Delete"].exists)
        app.sheets.buttons["Delete"].tap()

        app.sheets.buttons.element(boundBy: 0).tap()

        let sleep = expectation(description: "Sleep")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            sleep.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssert(!app.tables.cells.containing(.staticText, identifier: name).firstMatch.exists)
    }

    // check private key exist in Me & Contacts tab
    func checkExist(name: String, isExist: Bool) {
        let app = XCUIApplication()
        app.launch()

        // Move to "Me" tab
        XCTAssert(app.navigationBars["Messages"].exists)
        XCTAssert(app.tabBars.buttons.count == 3)
        XCTAssert(app.tabBars.buttons["Me"].exists)
        app.tabBars.buttons["Me"].tap()

        XCTAssertEqual(app.tables.cells.staticTexts[name].exists, isExist)

        // Move to "Contacts" tab
        XCTAssert(app.navigationBars["Me"].exists)
        XCTAssert(app.tabBars.buttons.count == 3)
        XCTAssert(app.tabBars.buttons["Contacts"].exists)
        app.tabBars.buttons["Contacts"].tap()

        XCTAssertEqual(app.tables.cells.staticTexts[name].exists, isExist)
    }

}

