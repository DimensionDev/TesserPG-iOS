//
//  UIColor.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-9-16.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

extension UIColor {

    static let separator: UIColor = ._systemGray

}

// MARK: - System
extension UIColor {

    static let _label: UIColor = {
        let _label = UIColor.black

        if #available(iOS 13, *) {
            return .label
        } else {
            return _label
        }
    }()

    static let _secondaryLabel: UIColor = {
        let _secondaryLabel = UIColor(displayP3Red: 60.0/255.0, green: 60.0/255.0, blue: 67.0/255.0, alpha: 0.6)

        if #available(iOS 13, *) {
            return .secondaryLabel
        } else {
            return _secondaryLabel
        }
    }()

    static let _tertiaryLabel: UIColor = {
        let _tertiaryLabel = UIColor(displayP3Red: 60.0/255.0, green: 60.0/255.0, blue: 67.0/255.0, alpha: 0.3)

        if #available(iOS 13, *) {
            return .tertiaryLabel
        } else {
            return _tertiaryLabel
        }
    }()

}

extension UIColor {

    static let _systemGray: UIColor = {
        let _systemGray = UIColor(displayP3Red: 142.0/255.0, green: 142.0/255.0, blue: 147.0/255.0, alpha: 1.0)

        if #available(iOS 13, *) {
            return .systemGray
        } else {
            return _systemGray
        }
    }()

    static let _systemGray2: UIColor = {
        let _systemGray2 = UIColor(displayP3Red: 174.0/255.0, green: 174.0/255.0, blue: 178.0/255.0, alpha: 1.0)

        if #available(iOS 13, *) {
            return .systemGray2
        } else {
            return _systemGray2
        }
    }()

    static let _systemGray3: UIColor = {
        let _systemGray3 = UIColor(displayP3Red: 199.0/255.0, green: 199.0/255.0, blue: 204.0/255.0, alpha: 1.0)

        if #available(iOS 13, *) {
            return .systemGray3
        } else {
            return _systemGray3
        }
    }()

    static let _systemGray4: UIColor = {
        let _systemGray4 = UIColor(displayP3Red: 209.0/255.0, green: 209.0/255.0, blue: 214.0/255.0, alpha: 1.0)

        if #available(iOS 13, *) {
            return .systemGray4
        } else {
            return _systemGray4
        }
    }()

    static let _systemGray5: UIColor = {
        let _systemGray5 = UIColor(displayP3Red: 229.0/255.0, green: 229.0/255.0, blue: 234.0/255.0, alpha: 1.0)

        if #available(iOS 13, *) {
            return .systemGray5
        } else {
            return _systemGray5
        }
    }()

    static let _systemGray6: UIColor = {
        let _systemGray6 = UIColor(displayP3Red: 242.0/255.0, green: 242.0/255.0, blue: 247.0/255.0, alpha: 1.0)

        if #available(iOS 13, *) {
            return .systemGray6
        } else {
            return _systemGray6
        }
    }()

}

extension UIColor {

    static let _systemBackground: UIColor = {
        let _systemBackground = UIColor.white

        if #available(iOS 13, *) {
            return .systemBackground
        } else {
            return _systemBackground
        }
    }()

    static let _secondarySystemBackground: UIColor = {
        let _secondarySystemBackground = UIColor(displayP3Red: 239.0/255.0, green: 239.0/255.0, blue: 244.0/255.0, alpha: 1.0)

        if #available(iOS 13, *) {
            return .secondarySystemBackground
        } else {
            return _secondarySystemBackground
        }
    }()

    static let _tertiarySystemBackground: UIColor = {
        let _tertiarySystemBackground = UIColor.white

        if #available(iOS 13.0, *) {
            return .tertiarySystemBackground
        } else {
            return _tertiarySystemBackground
        }
    }()

}

extension UIColor {

    static let _systemGroupedBackground: UIColor = {
        let _systemGroupedBackground = UIColor(displayP3Red: 242.0/255.0, green: 242.0/255.0, blue: 247.0/255.0, alpha: 1.0)

        if #available(iOS 13, *) {
            return .systemGroupedBackground
        } else {
            return _systemGroupedBackground
        }
    }()

    static let _secondarySystemGroupedBackground: UIColor = {
        let _secondarySystemGroupedBackground = UIColor.white

        if #available(iOS 13, *) {
            return .secondarySystemGroupedBackground
        } else {
            return _secondarySystemGroupedBackground
        }
    }()

    static let _tertiarySystemGroupedBackground: UIColor = {
        let _tertiarySystemGroupedBackground = UIColor(displayP3Red: 242.0/255.0, green: 242.0/255.0, blue: 247.0/255.0, alpha: 1.0)

        if #available(iOS 13, *) {
            return .tertiarySystemGroupedBackground
        } else {
            return _tertiarySystemGroupedBackground
        }
    }()

}
