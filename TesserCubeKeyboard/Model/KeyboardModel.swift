//
//  KeyboardModel.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/2/20.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

var counter = 0

enum ShiftState {
    case disabled
    case enabled
    case locked
    
    func uppercase() -> Bool {
        switch self {
        case .disabled:
            return false
        case .enabled:
            return true
        case .locked:
            return true
        }
    }
}

class Keyboard {
    var pages: [Page] = []
    
    func add(key: Key, row: Int, page: Int) {
        if self.pages.count <= page {
            for _ in self.pages.count...page {
                self.pages.append(Page())
            }
        }
        
        self.pages[page].add(key: key, row: row)
    }
}

class Page {
    var rows: [[Key]] = []
    
    func add(key: Key, row: Int) {
        if self.rows.count <= row {
            for _ in self.rows.count...row {
                self.rows.append([])
            }
        }
        
        self.rows[row].append(key)
    }
}

class Key: Hashable {
    
    enum TCKeyboardKeyType {
        case character
        case specialCharacter
        case shift
        case backspace
        case modeChange
        case keyboardChange
        case period
        case space
        case `return`
        case settings
        case other
    }
    
    var type: TCKeyboardKeyType
    var uppercaseKeyCap: String?
    var lowercaseKeyCap: String?
    var uppercaseOutput: String?
    var lowercaseOutput: String?
    var toMode: Int? //if the key is a mode button, this indicates which page it links to
    
    var isCharacter: Bool {
        get {
            switch self.type {
            case
            .character,
            .specialCharacter,
            .period:
                return true
            default:
                return false
            }
        }
    }
    
    var isSpecial: Bool {
        get {
            switch self.type {
            case .shift:
                return true
            case .backspace:
                return true
            case .modeChange:
                return true
            case .keyboardChange:
                return true
            case .return:
                return true
            case .settings:
                return true
            default:
                return false
            }
        }
    }
    
    var hasOutput: Bool {
        get {
            return (self.uppercaseOutput != nil) || (self.lowercaseOutput != nil)
        }
    }
    
    // TODO: this is kind of a hack
    var hashValue: Int
    
    init(_ type: TCKeyboardKeyType) {
        self.type = type
        self.hashValue = counter
        counter += 1
    }
    
    convenience init(_ key: Key) {
        self.init(key.type)
        
        self.uppercaseKeyCap = key.uppercaseKeyCap
        self.lowercaseKeyCap = key.lowercaseKeyCap
        self.uppercaseOutput = key.uppercaseOutput
        self.lowercaseOutput = key.lowercaseOutput
        self.toMode = key.toMode
    }
    
    func setLetter(_ letter: String) {
        self.lowercaseOutput = letter.lowercased()
        self.uppercaseOutput = letter.uppercased()
        self.lowercaseKeyCap = self.lowercaseOutput
        self.uppercaseKeyCap = self.uppercaseOutput
    }
    
    func outputForCase(_ uppercase: Bool) -> String {
        if uppercase {
            return uppercaseOutput ?? lowercaseOutput ?? ""
        }
        else {
            return lowercaseOutput ?? uppercaseOutput ?? ""
        }
    }
    
    func keyCapForCase(_ uppercase: Bool) -> String {
        if uppercase {
            return uppercaseKeyCap ?? lowercaseKeyCap ?? ""
        }
        else {
            return lowercaseKeyCap ?? uppercaseKeyCap ?? ""
        }
    }
    
    static func ==(lhs: Key, rhs: Key) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

// MARK: Return Key Type Title
extension UIReturnKeyType {
    var title: String {
        var returnKeyText = L10n.Keyboard.KeyCap.Return.return
        switch self {
        case .search:
            returnKeyText = L10n.Keyboard.KeyCap.Return.search
        case .send:
            returnKeyText = L10n.Keyboard.KeyCap.Return.send
        case .go:
            returnKeyText = L10n.Keyboard.KeyCap.Return.go
        case .continue:
            returnKeyText = L10n.Keyboard.KeyCap.Return.continue
        case .done:
            returnKeyText = L10n.Keyboard.KeyCap.Return.done
        case .emergencyCall:
            returnKeyText = L10n.Keyboard.KeyCap.Return.emergencyCall
        case .google:
            returnKeyText = L10n.Keyboard.KeyCap.Return.google
        case .join:
            returnKeyText = L10n.Keyboard.KeyCap.Return.join
        case .next:
            returnKeyText = L10n.Keyboard.KeyCap.Return.next
        case .route:
            returnKeyText = L10n.Keyboard.KeyCap.Return.route
        case .yahoo:
            returnKeyText = L10n.Keyboard.KeyCap.Return.yahoo
        default:
            break
        }
        return returnKeyText
    }
}
