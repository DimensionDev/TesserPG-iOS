//: A UIKit based Playground for presenting user interface
  
import UIKit

func getSuggestion(for word: String) -> [String] {
    let checker = UITextChecker()
    let range = NSRange(location: 0, length: word.count)
    let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: range.location, wrap: true, language: "en_US")
    
    let arrGuessed = checker.guesses(forWordRange: misspelledRange, in: word, language: "en_US")
    return arrGuessed ?? [word]

}

let guessed = getSuggestion(for: "l")
for guess in (guessed) {
    print("I Guess: \(guess)")
}


