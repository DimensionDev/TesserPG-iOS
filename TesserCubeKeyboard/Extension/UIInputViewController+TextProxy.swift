//
//  UIInputViewController+TextProxy.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/3/7.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

extension UIInputViewController {
    func removeAllBeforeContent() {
        while (textDocumentProxy.documentContextBeforeInput?.count ?? 0) > 0 {
            textDocumentProxy.deleteBackward()
        }
    }
    
    func removeAllContent() {
        if let shiftCount = textDocumentProxy.documentContextAfterInput?.count, shiftCount > 0 {
            textDocumentProxy.adjustTextPosition(byCharacterOffset: shiftCount)
        }
        removeAllBeforeContent()
    }
    
    var lastWord: String {
        return textDocumentProxy.documentContextBeforeInput?.components(separatedBy: " ").last ?? ""
    }
    
    func replaceLastWord(by input: String) {
        
        if #available(iOSApplicationExtension 11.0, *), let _ = textDocumentProxy.selectedText  {
            // Do nothing
        } else {
            let lastWordLength = lastWord.count
            for _ in 0..<lastWordLength {
                textDocumentProxy.deleteBackward()
            }
        }
        textDocumentProxy.insertText(input)
    }
}
