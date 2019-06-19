//
//  UserDefaults+AppGroup.swift
//  TesserCube
//
//  Created by jk234ert on 2019/2/20.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import UIKit

extension UserDefaults {
    static let shared = UserDefaults(suiteName: "group.com.sujitech.tessercube")
}

extension UserDefaults {
    subscript<T: RawRepresentable>(key: String) -> T? {
        get {
            if let rawValue = value(forKey: key) as? T.RawValue {
                return T(rawValue: rawValue)
            }
            return nil
        }
        set { set(newValue?.rawValue, forKey: key) }
    }
    
    subscript<T>(key: String) -> T? {
        get { return value(forKey: key) as? T }
        set { set(newValue, forKey: key) }
    }
}

struct Preference {
    
    static var isAcceptedPrivacy: Bool {
        get { return UserDefaults.standard[#function] ?? false }
        set { UserDefaults.standard[#function] = newValue }
    }
    
    static var isFirstTimeLaunch: Bool {
        get { return UserDefaults.standard[#function] ?? true }
        set { UserDefaults.standard[#function] = newValue }
    }
    
    static var dbVersion: Int {
        get { return UserDefaults.standard[#function] ?? 0 }
        set { UserDefaults.standard[#function] = newValue }
    }

}

struct KeyboardPreference {

    static var accountName: String? {
        get { return UserDefaults.shared?[#function] }
        set { UserDefaults.shared?[#function] = newValue }
    }
    
    static var kKeyboardClicks: Bool {
        get { return UserDefaults.shared?[#function] ?? true }
        set { UserDefaults.shared?[#function] = newValue }
    }
    
    static var kSmallLowercase: Bool {
        get { return UserDefaults.shared?[#function] ?? true }
        set { UserDefaults.shared?[#function] = newValue }
    }
    
    static var kPeriodShortcut: Bool {
        get { return UserDefaults.shared?[#function] ?? true }
        set { UserDefaults.shared?[#function] = newValue }
    }
    
    static var kAutoCapitalization: Bool {
        get { return UserDefaults.shared?[#function] ?? true }
        set { UserDefaults.shared?[#function] = newValue }
    }

    static var kMessageDigitalSignatureSettings: MessageDigitalSignatureSettings {
        get { return UserDefaults.shared?[#function] ?? .automatic }
        set { UserDefaults.shared?[#function] = newValue }
    }

}
