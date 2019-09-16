//
//  SuggestionStackView.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/3/4.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

protocol SuggesionViewDelegate: class {
    func suggestionView(_ view: SuggestionView, didClick suggest: String)
}

class SuggestionView: UIView, Thematic {
    
    weak var delegate: SuggesionViewDelegate?
    
    private var stackView: UIStackView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configUI()
    }
    
    private func configUI() {
        
        createStackView()
        setupConstraints()
        setupSubViews()
    }
    
    func updateColor(theme: Theme) {
        switch theme {
        case .light:
            backgroundColor = .keyboardBackgroundLight
        case .dark:
            backgroundColor = .keyboardBackgroundDark
        }
    }
    
    private func createStackView() {
        stackView = UIStackView(frame: .zero)
        stackView.axis = .horizontal
        stackView.alignment = .bottom
        stackView.distribution = .fill
        stackView.spacing = 0
        addSubview(stackView)
    }
    
    private func setupConstraints() {
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupSubViews() {
        let button1 = SuggestionButton(type: .custom)
        button1.setTitle("I", for: .normal)
        stackView.addArrangedSubview(button1)
        button1.snp.makeConstraints { make in
//            make.width.equalTo(self.snp.width).offset(-3.0 * SeparatorView.separatorWidth).multipliedBy(1.0 / 3.0)
            make.height.equalTo(36)
        }

        button1.addTarget(self, action: #selector(suggestButtonDidClicked(_:)), for: .touchUpInside)
        
        let separator2 = SeparatorView()
        stackView.addArrangedSubview(separator2)
        let button2 = SuggestionButton(type: .custom)
        button2.setTitle("This", for: .normal)
        stackView.addArrangedSubview(button2)
        button2.snp.makeConstraints { make in
            make.width.equalTo(button1.snp.width)
            make.height.equalTo(36)
        }

        button2.addTarget(self, action: #selector(suggestButtonDidClicked(_:)), for: .touchUpInside)
        
        separator2.snp.makeConstraints { make in
            make.width.equalTo(SeparatorView.separatorWidth)
            make.height.equalToSuperview()
        }
        
        let separator3 = SeparatorView()
        stackView.addArrangedSubview(separator3)
        let button3 = SuggestionButton(type: .custom)
        button3.setTitle("The", for: .normal)
        stackView.addArrangedSubview(button3)
        button3.snp.makeConstraints { make in
            make.width.equalTo(button1.snp.width)
            make.height.equalTo(36)
        }
        button3.addTarget(self, action: #selector(suggestButtonDidClicked(_:)), for: .touchUpInside)
        
        separator3.snp.makeConstraints { make in
            make.width.equalTo(SeparatorView.separatorWidth)
            make.height.equalToSuperview()
        }
    }
    
    func updateSuggesions(_ suggestions: [String]) {
        assert(stackView.arrangedSubviews.count == 5)

        let firstSuggest = suggestions.first ?? ""
        if let button = stackView.arrangedSubviews[0] as? UIButton {
            button.setTitle(firstSuggest, for: .normal)
            button.isEnabled = !firstSuggest.isEmpty
        }

        let secondSuggest = suggestions.count > 1 ? suggestions[1] : ""
        if let button = stackView.arrangedSubviews[2] as? UIButton {
            button.setTitle(secondSuggest, for: .normal)
            button.isEnabled = !secondSuggest.isEmpty
        }
        
        let thirdSuggest = suggestions.count > 2 ? suggestions[2] : ""
        if let button = stackView.arrangedSubviews[4] as? UIButton {
            button.setTitle(thirdSuggest, for: .normal)
            button.isEnabled = !thirdSuggest.isEmpty
        }
    }
    
    @objc
    private func suggestButtonDidClicked(_ sender: SuggestionButton) {
        delegate?.suggestionView(self, didClick: sender.title(for: .normal) ?? "")
    }
}
