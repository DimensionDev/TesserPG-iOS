//
//  PassphraseTextField.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-8.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

public class PassphraseTextField: UITextField {

    private let bottomBorderView = UIView()

    public override init(frame: CGRect) {
        super.init(frame: frame)

        placeholder = "Password"
        keyboardType = .asciiCapable
        backgroundColor = .white        // FIXME:

        bottomBorderView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomBorderView)
        NSLayoutConstraint.activate([
            bottomBorderView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomBorderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomBorderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBorderView.heightAnchor.constraint(equalToConstant: 0.5)
        ])

        bottomBorderView.backgroundColor = UIColor(red: 200.1/255.0, green: 198.8/255.0, blue: 204.3/255.0, alpha: 1.0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
