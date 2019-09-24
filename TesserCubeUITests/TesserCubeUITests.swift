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

extension TesserCubeUITests {

    func testSnapshot() throws {
        // Reset application
        let _app = XCUIApplication()
        _app.launchArguments.append("ResetApplication")
        _app.launch()
        _app.terminate()

        skipWizard()
        createKey(name: "Alice", email: "alice@tessercube.com", password: "Alice")
        createKey(name: "Bob", email: "bob@tessercube.com", password: "Bob")

        aliceComposeMessageToBob()
        bobComposeMessageToAlice()

        // Copy message from bob then remove bob key secret part. Interpet use alice key.
        let messageFromBob = copyFirstMessagePGPArmor()
        deleteFirstMessage()
        deleteKeySecretPart(name: "Bob")
        interpretMessage(message: messageFromBob)

        // Create several contacts for screenshot
        createKeyThenDeleteSecretPart(name: "Carol")
        createKeyThenDeleteSecretPart(name: "Dan")
        createKeyThenDeleteSecretPart(name: "Erin")

        let app = XCUIApplication()
        app.launch()

        XCTAssert(app.tabBars.buttons["Compose"].waitForExistence(timeout: 5.0))
        app.tabBars.buttons["Compose"].tap()
        try app.snapshot()

        XCTAssert(app.tabBars.buttons["Messages"].waitForExistence(timeout: 5.0))
        app.tabBars.buttons["Messages"].tap()
        try app.snapshot()

        XCTAssert(app.tabBars.buttons["Me"].waitForExistence(timeout: 5.0))
        app.tabBars.buttons["Me"].tap()
        try app.snapshot()
    }

}

extension TesserCubeUITests {

    // test create keypair and delete in me tab
    func testKeyCreateAndRemove_1() {
        resetApplication()
        skipWizard()

        // Not exist
        XCTAssertFalse(checkContactExist(name: "Bob"))
        XCTAssertFalse(checkMeExist(name: "Bob <bob@tessercube.com>"))
        // Create Bob
        createKey(name: "Bob", email: "bob@tessercube.com", password: "Bob")
        // Exist
        XCTAssertTrue(checkContactExist(name: "Bob"))
        XCTAssertTrue(checkMeExist(name: "Bob <bob@tessercube.com>"))
        // Delete
        deleteKey(name: "Bob <bob@tessercube.com>")
        // Not exist
        XCTAssertFalse(checkContactExist(name: "Bob"))
        XCTAssertFalse(checkMeExist(name: "Bob <bob@tessercube.com>"))
    }

    // TODO: test create and delete key secret part in contact edit view
    // TODO: test create and delete whole key in contact edit view

}

extension TesserCubeUITests {

    // test sender if or not interpret self signing cipher message
    func testInterpretEnctypedAndSignedMessage() {
        resetApplication()
        skipWizard()

        createKey(name: "Alice", email: "alice@tessercube.com", password: "Alice")
        createKey(name: "Bob", email: "bob@tessercube.com", password: "Bob")
        aliceComposeMessageToBob(message: "From Alice")
        let messageFromBob = copyFirstMessagePGPArmor()
        deleteFirstMessage()
        deleteKey(name: "Bob <bob@tessercube.com>")
        interpretMessage(message: messageFromBob)

        let app = XCUIApplication()
        print(app.debugDescription)
        XCTAssert(app.tables.cells.containing(.staticText, identifier: "From Alice").firstMatch.waitForExistence(timeout: 5.0))
    }

    func testCreateKeyUseInvalidUserID_1() {
        resetApplication()
        skipWizard()

        let title = "Name cannot contain the following characters: <>()"
        XCTAssertEqual(createKey(name: "Alice <", email: "alice@tessercube.com", password: "Alice")?.staticTexts.firstMatch.label, title)
        XCTAssertEqual(createKey(name: "Alice >", email: "alice@tessercube.com", password: "Alice")?.staticTexts.firstMatch.label, title)
        XCTAssertEqual(createKey(name: "Alice (", email: "alice@tessercube.com", password: "Alice")?.staticTexts.firstMatch.label, title)
        XCTAssertEqual(createKey(name: "Alice )", email: "alice@tessercube.com", password: "Alice")?.staticTexts.firstMatch.label, title)

        let title2 = "Please input a valid email address"
        XCTAssertEqual(createKey(name: "Alice", email: "alice<@tessercube.com", password: "Alice")?.staticTexts.firstMatch.label, title2)
        XCTAssertEqual(createKey(name: "Alice", email: "alice>@tessercube.com", password: "Alice")?.staticTexts.firstMatch.label, title2)
        XCTAssertEqual(createKey(name: "Alice", email: "alice(@tessercube.com", password: "Alice")?.staticTexts.firstMatch.label, title2)
        XCTAssertEqual(createKey(name: "Alice", email: "alice)@tessercube.com", password: "Alice")?.staticTexts.firstMatch.label, title2)

        XCTAssertNil(createKey(name: "Alice", email: "alice@tessercube.com", password: "Alice"))
    }

}

extension TesserCubeUITests {

    func resetApplication() {
        let app = XCUIApplication()
        app.launchArguments.append("ResetApplication")
        app.launch()
        app.terminate()
    }

    func aliceComposeMessageToBob(message: String = "Hi, Bob. What time shall we meet tonight for a drink?") {
       let app = XCUIApplication()
       app.launch()

       // compose
       app.buttons["Compose"].tap()

       // select bob
       XCTAssert(app.buttons["plus.circle"].waitForExistence(timeout: 5.0))
       app.buttons["plus.circle"].tap()
       let cell = app.tables.cells.containing(.staticText, identifier: "Bob").firstMatch
       XCTAssert(cell.waitForExistence(timeout: 5.0))
       cell.tap()
       app.buttons["Done"].tap()

       // type compose message
       let textView = app.textViews.firstMatch
       XCTAssert(textView.waitForExistence(timeout: 5.0))
       textView.tap()
       textView.typeText(message)
       app.buttons["Finish"].tap()

       print(app.debugDescription)
   }

   func bobComposeMessageToAlice() {
       let app = XCUIApplication()
       app.launch()

       // Compose
       app.buttons["Compose"].tap()

       // Select bob
       XCTAssert(app.buttons["plus.circle"].waitForExistence(timeout: 5.0))
       app.buttons["plus.circle"].tap()

       print(app.debugDescription)

       let cell = app.tables["ContactsTableView"].cells.containing(.staticText, identifier: "Alice").firstMatch
       XCTAssert(cell.waitForExistence(timeout: 5.0))
       cell.tap()
       app.buttons["Done"].tap()

       // select Bob as sender
       let window = app.windows.element(boundBy: 0)
       let appWindowHeight = window.frame.height
       print(appWindowHeight)

       let textField = app.textFields["Alice"].firstMatch
       XCTAssert(textField.waitForExistence(timeout: 5.0))
       textField.tap()

       // Tap to select Bob
       let pickerWheel = app.pickerWheels.firstMatch
       XCTAssert(pickerWheel.waitForExistence(timeout: 5.0))
       pickerWheel.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: pickerWheel.frame.midX, dy: pickerWheel.frame.height * 0.5 + 20)).tap()
       app.buttons["Done"].tap()

       // Type compose message
       let textView = app.textViews.firstMatch
       XCTAssert(textView.waitForExistence(timeout: 5.0))
       textView.tap()
       textView.typeText("Meet at eight in the evening.")
       app.buttons["Finish"].tap()

       print(app.debugDescription)
   }

}

extension TesserCubeUITests {

    func deleteFirstMessage() {
        let app = XCUIApplication()
        app.launch()

        // Check name exists
        let card = app.tables.cells.element(boundBy: 0)
        XCTAssert(card.waitForExistence(timeout: 5.0))

        card.tap()
        app.buttons["Delete"].tap()
    }

    func interpretMessage(message: String) {
        let app = XCUIApplication()
        app.launch()

        UIPasteboard.general.string = message

        XCTAssert(app.buttons["Interpret"].waitForExistence(timeout: 5.0))
        app.buttons["Interpret"].tap()

        // Wait 5s
        let sleep = expectation(description: "Sleep")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            sleep.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)

        app.buttons["Finish"].tap()

        // Wait 5s
        let sleep2 = expectation(description: "Sleep")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            sleep2.fulfill()
        }
        wait(for: [sleep2], timeout: 5.0)
    }

    func copyFirstMessagePGPArmor() -> String {
        let app = XCUIApplication()
        app.launch()

        // Check card exists
        let card = app.tables.cells.element(boundBy: 0)
        XCTAssert(card.waitForExistence(timeout: 5.0))

        // Copy
        card.tap()
        XCTAssert(app.sheets.buttons["Share Encrypted Message"].exists)
        app.sheets.buttons["Share Encrypted Message"].tap()

        // Wait 5s
        let sleep = expectation(description: "Sleep")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            sleep.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)

        // Tap Copy
        print(app.collectionViews.cells.firstMatch.exists)
        app.collectionViews.cells.firstMatch.tap()

        return UIPasteboard.general.string!
    }

    func createKeyThenDeleteSecretPart(name: String) {
        createKey(name: name, email: name + "@tessercube.com", password: name)
        deleteKeySecretPart(name: name)
    }

    // delete key secret part by name
    func deleteKeySecretPart(name: String) {
        let app = XCUIApplication()
        app.launch()

        XCTAssert(app.tabBars.buttons["Contacts"].exists)
        app.tabBars.buttons["Contacts"].tap()

        let cell = app.tables.cells.containing(.staticText, identifier: name).firstMatch
        XCTAssert(cell.waitForExistence(timeout: 5.0))
        cell.tap()

        XCTAssert(app.buttons["Edit"].waitForExistence(timeout: 5.0))
        app.buttons["Edit"].tap()

        XCTAssert(app.buttons["Delete Contact"].waitForExistence(timeout: 5.0))
        app.buttons["Delete Contact"].tap()

        XCTAssert(app.buttons["Delete"].waitForExistence(timeout: 5.0))
        app.buttons["Delete"].tap()

        XCTAssert(app.buttons["Keep Public Key"].waitForExistence(timeout: 5.0))
        app.buttons["Keep Public Key"].tap()
    }

    // Skip wizard if needs
    func skipWizard() {
        let app = XCUIApplication()
        app.launch()

        if app.buttons["Skip Guides"].waitForExistence(timeout: 5.0) {
            app.buttons["Skip Guides"].tap()
        }
    }

    // create private key by name
    @discardableResult
    func createKey(name: String, email: String, password: String) -> XCUIElement? {
        let app = XCUIApplication()
        app.launch()

        // Move to "Me" tab
        XCTAssert(app.navigationBars["Messages"].exists)
        XCTAssert(app.tabBars.buttons.count == 3)
        XCTAssert(app.tabBars.buttons["Me"].exists)
        app.tabBars.buttons["Me"].tap()

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

        if app.alerts.firstMatch.waitForExistence(timeout: 3.0) {
            return app.alerts.firstMatch
        } else {
            return nil
        }
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
        XCTAssert(app.tabBars.buttons["Me"].exists)
        app.tabBars.buttons["Me"].tap()

        let card = app.tables.cells.containing(.staticText, identifier: name).firstMatch
        XCTAssert(card.exists)
        card.tap()

        // Tap "Create Keypair" action
        XCTAssert(app.sheets.buttons["Delete"].exists)
        app.sheets.buttons["Delete"].tap()

        XCTAssert(app.sheets.buttons.firstMatch.waitForExistence(timeout: 5.0))
        app.sheets.buttons.firstMatch.tap()
    }

    // check private key exist in Contacts tab
    func checkContactExist(name: String) -> Bool {
        let app = XCUIApplication()
        app.launch()

        // Move to "Contacts" tab
        XCTAssert(app.tabBars.buttons["Contacts"].waitForExistence(timeout: 5.0))
        app.tabBars.buttons["Contacts"].tap()

        return app.tables.cells.staticTexts[name].exists
    }

    // check private key exist in Me tab
    func checkMeExist(name: String) -> Bool {
        let app = XCUIApplication()
        app.launch()

        // Move to "Me" tab
        XCTAssert(app.tabBars.buttons["Me"].exists)
        app.tabBars.buttons["Me"].tap()

        return app.tables.cells.staticTexts[name].exists
    }

}

