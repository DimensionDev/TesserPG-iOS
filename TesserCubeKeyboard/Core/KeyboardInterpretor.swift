//
//  KeyboardInterpretor.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/30.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

typealias InterpretCompletion = (Bool, Error?, Message?) -> Void

class KeyboardInterpretor {
    
    static let inputQueue = DispatchQueue(label: "input")
    static func interpret(textDocumentProxy: UITextDocumentProxy, _ completion: InterpretCompletion? = nil) {
        inputQueue.async {
            getAllString(textDocumentProxy: textDocumentProxy, completion)
        }
        return
    }
    
    private static func getAllString(textDocumentProxy: UITextDocumentProxy, _ completion: InterpretCompletion? = nil) {
        let interval: TimeInterval = 0.02
        
        // 1. Fetch all content BEFORE current cursor's position
        var beforeText = ""
        while let lineContent = textDocumentProxy.documentContextBeforeInput, !lineContent.isEmpty {
            
            beforeText = lineContent.appending(beforeText)
            
            Thread.sleep(forTimeInterval: interval)
            textDocumentProxy.adjustTextPosition(byCharacterOffset: lineContent.count * -1)
            Thread.sleep(forTimeInterval: interval)
        }
        // 2. Re-locate cursor to original position after fetching text before
        textDocumentProxy.adjustTextPosition(byCharacterOffset: beforeText.count)
        
        // 3. Fetch all content AFTER current cursor's position
        
        // MARK: sleep to wait ajustTextPosition completion
        Thread.sleep(forTimeInterval: interval)
        var afterText = ""
        while let lineContent = textDocumentProxy.documentContextAfterInput, !lineContent.isEmpty {
            
            afterText = afterText.appending(lineContent)
            
            Thread.sleep(forTimeInterval: interval)
            textDocumentProxy.adjustTextPosition(byCharacterOffset: lineContent.count)
            Thread.sleep(forTimeInterval: interval)
        }
        // 4. Re-locate cursor to original position after fetching text after
        textDocumentProxy.adjustTextPosition(byCharacterOffset: afterText.count)
        Thread.sleep(forTimeInterval: interval)
        
        // 5. Concatenate before & after text to be interpreted
        let toInterpretedText = beforeText.appending(afterText)
        do {
            let result = try decryptMessage(toInterpretedText)
            DispatchQueue.main.async {
                completion?(true, nil, result)
            }
        } catch let error {
            completion?(false, error, nil)
        }
    }
    
    static func interpretMessage(_ message: String, _ completion: InterpretCompletion? = nil) {
        do {
            let result = try decryptMessage(message)
            DispatchQueue.main.async {
                completion?(true, nil, result)
            }
        } catch let error {
            completion?(false, error, nil)
        }
    }
    
    private static func decryptMessage(_ message: String) throws -> Message? {
        do {
            return try ProfileService.default.decryptMessage(message)
        } catch let error {
            throw error
        }
    }
}
