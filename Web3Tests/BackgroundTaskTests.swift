//
//  BackgroundTaskTests.swift
//  Web3Tests
//
//  Created by Cirno MainasuK on 2019-12-13.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import XCTest
import os
import Web3

class BackgroundTaskTests: XCTestCase {

    var web3: Web3!

//    override func setUp() {
//        let backgroundSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "web3")
//        let session = URLSession(configuration: backgroundSessionConfiguration)
//        web3 = Web3(rpcURL: "https://rinkeby.infura.io/v3/823d2b1356e24d7fbd3b1ae954c6db19", session: session)
//    }
    
    func testSmoke() {
        
    }

}

extension BackgroundTaskTests {

    func testClientVersion() {
        let clientVersionExpectation = expectation(description: "clientVersionExpectation")
        
        firstly {
            web3.clientVersion()
        }.done { version in
            print(version)
            clientVersionExpectation.fulfill()
        }.catch { error in
            print("Error")
        }
        
        wait(for: [clientVersionExpectation], timeout: 10.0)
    }

}

/*
extension BackgroundTaskTests {
    
    func testBackgroundTask() {
        let endBackgroundTaskExpectation = expectation(description: "background task end")
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
            endBackgroundTaskExpectation.fulfill()
        }
        
        XCTAssertNotNil(backgroundTask)
        
        wait(for: [endBackgroundTaskExpectation], timeout: 30)
    }
    
    func endBackgroundTask() {
        os_log("%{public}s[%{public}ld], %{public}s: Background task end", ((#file as NSString).lastPathComponent), #line, #function)
        UIApplication.shared.endBackgroundTask(backgroundTask)
    }
    
}
*/
