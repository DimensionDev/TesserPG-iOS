//
//  SuggestHelper.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/3/7.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class SuggestHelper {
    static let defaultSuggestions = ["I", "This", "The"]
    
    class func getSuggestion(_ input: String, lexicon: UILexicon?) -> [String] {
        if input.isEmpty {
            return defaultSuggestions
        }
        var suggesions = [String]()
        if let availableLexicon = lexicon {
            for entry in availableLexicon.entries {
                if entry.userInput == input {
                    suggesions.append(entry.documentText)
                    break
                }
            }
        }
        suggesions.append(contentsOf: getSuggesionsFromTextChecked(input))
        return suggesions
    }
    
    class func getSuggesionsFromTextChecked(_ input: String) -> [String] {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: input.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: input, range: range, startingAt: range.location, wrap: true, language: "en_US")
        
        let arrGuessed = checker.guesses(forWordRange: misspelledRange, in: input, language: "en_US")
        return arrGuessed ?? [input]
    }
}

