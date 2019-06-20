//
//  IntroWizardViewController.swift
//  TesserCube
//
//  Created by jk234ert on 2019/6/16.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit

@objc
protocol IntroWizardViewControllerDataSource: class {
    func numberOfSteps(in viewController: IntroWizardViewController) -> Int
    func introWizardViewController(_ viewController: IntroWizardViewController, spotLightOfStepAt index: Int) -> IntroSpotlight?
    func introWizardViewController(_ viewController: IntroWizardViewController, arrowOfStepAt index: Int) -> IntroArrow?
    func introWizardViewController(_ viewController: IntroWizardViewController, guideTextAt index: Int) -> String?
}

@objc
protocol IntroWizardViewContorllerDelegate: class {
    @objc optional func introWizardViewControllerWillPresent(_ viewController: IntroWizardViewController)
    
    @objc optional func introWizardViewController(_ viewController: IntroWizardViewController, willNavigateTo index: Int)
    
    @objc optional func introWizardViewController(_ viewController: IntroWizardViewController, willDismissAt index: Int)
    
    @objc optional func createKeyButtonDidClicked(_ viewController: IntroWizardViewController)
    
    @objc optional func importKeyButtonDidClicked(_ viewController: IntroWizardViewController)
    
    @objc optional func nowNowButtonDidClicked(_ viewController: IntroWizardViewController)
}

class IntroWizardViewController: UIViewController {
    
    weak var delegate: IntroWizardViewContorllerDelegate?
    weak var dataSource: IntroWizardViewControllerDataSource?
    
    private var stepsCount = 0
    private var currentIndex = 0
    
    var bgView: UIView?
    var arrowImageView: UIImageView?
    
    private lazy var blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blurEffect)
        view.alpha = 0.86
        return view
    }()
    
    private lazy var darkView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return view
    }()
    
    private var cardView: IntroCardView = {
        let view = IntroCardView()
        return view
    }()
    
    private var skipButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = FontFamily.SFProDisplay.regular.font(size: 17)
        button.setTitle(L10n.IntroWizardViewController.Action.Button.skipGuides, for: .normal)
        return button
    }()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        modalPresentationStyle = .overCurrentContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(dataSource != nil, "dataSource of IntroWizardViewController must not be nil")
        
        stepsCount = dataSource?.numberOfSteps(in: self) ?? 0
        assert(stepsCount > 0, "number of steps of IntroWizardViewController must be large than 0")
        
        view.backgroundColor = .clear
        
        setupBgView()
        setupCardView()
        naivgateTo(index: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate?.introWizardViewControllerWillPresent?(self)
    }
    
    private func setupBgView() {
        if UIAccessibility.isReduceTransparencyEnabled {
            bgView = darkView
        } else {
            bgView = blurView
        }
        view.addSubview(bgView!)
        bgView?.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }
    
    private func setupCardView() {
        view.addSubview(cardView)
        view.addSubview(skipButton)
        cardView.snp.makeConstraints { maker in
            maker.leading.equalTo(view.layoutMarginsGuide)
            maker.trailing.equalTo(view.layoutMarginsGuide)
            maker.centerY.equalToSuperview()
        }
        skipButton.snp.makeConstraints { maker in
            maker.top.equalTo(cardView.snp.bottom).offset(20)
            maker.leading.equalTo(cardView.snp.leading).offset(60)
            maker.trailing.equalTo(cardView.snp.trailing).offset(-60)
        }
        
        cardView.nextButton.addTarget(self, action: #selector(nextButtonDidClicked), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(skipButtonDidClicked), for: .touchUpInside)
    }
    
    @objc private func nextButtonDidClicked() {
        currentIndex += 1
        naivgateTo(index: currentIndex)
    }
    
    @objc private func skipButtonDidClicked() {
        delegate?.introWizardViewController?(self, willDismissAt: currentIndex)
        dismiss(animated: true)
    }
    
    private func naivgateTo(index: Int) {
        guard index < stepsCount else {
            assert(false, "step index \(index) is out of stepsCount's range")
            return
        }
        
        // Remove exisiting layer masks & images
        bgView?.layer.mask = nil
        arrowImageView?.removeFromSuperview()
        arrowImageView = nil
        
        delegate?.introWizardViewController?(self, willNavigateTo: index)
        
        let guideText = dataSource?.introWizardViewController(self, guideTextAt: index)
        cardView.setGuideText(guideText ?? "")
        addSpotlight()
        addArrow()
        
        if index == (stepsCount - 1) {
            setupLastStepStyle()
        }
    }
    
    private func addSpotlight() {
        guard let spotlight = dataSource?.introWizardViewController(self, spotLightOfStepAt: currentIndex) else {
            return
        }
        let spotlightMask = CAShapeLayer()
        let clipPath = UIBezierPath(rect: view.bounds)
        let spotlightPath = spotlight.visiblePath
        clipPath.append(spotlightPath)
        spotlightMask.path = clipPath.cgPath
        spotlightMask.fillRule = .evenOdd
        bgView?.layer.mask = spotlightMask
    }
    
    private func addArrow() {
        guard let arrow = dataSource?.introWizardViewController(self, arrowOfStepAt: currentIndex) else {
            return
        }
        arrowImageView = UIImageView(frame: arrow.rect)
        arrowImageView?.image = arrow.direction.image
        view.addSubview(arrowImageView!)
    }
    
    private func setupLastStepStyle() {
        cardView.setLastStepStyle()
        skipButton.isHidden = true
        
        let createKeyButton = TCActionButton(frame: .zero)
        createKeyButton.color = Asset.sketchBlue.color
        createKeyButton.setTitleColor(.white, for: .normal)
        createKeyButton.setTitle(L10n.MeViewController.Action.Button.createKey, for: .normal)
        createKeyButton.addTarget(self, action: #selector(createKeyButtonDidClicked), for: .touchUpInside)
        
        let importKeyButton = TCActionButton(frame: .zero)
        importKeyButton.color = .white
        importKeyButton.setTitleColor(.black, for: .normal)
        importKeyButton.setTitle(L10n.MeViewController.Action.Button.importKey, for: .normal)
        importKeyButton.addTarget(self, action: #selector(importKeyButtonDidClicked), for: .touchUpInside)
        
        let notNowButton = TCActionButton(frame: .zero)
        notNowButton.color = .white
        notNowButton.setTitleColor(.black, for: .normal)
        notNowButton.setTitle(L10n.IntroWizardViewController.Action.Button.notNow, for: .normal)
        notNowButton.addTarget(self, action: #selector(notNowKeyButtonDidClicked), for: .touchUpInside)
        
        let actionsStackView = UIStackView(arrangedSubviews: [createKeyButton, importKeyButton, notNowButton], axis: .vertical, spacing: 12, alignment: .fill, distribution: .equalSpacing)
        view.addSubview(actionsStackView)
        actionsStackView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(cardView)
            maker.top.equalTo(cardView.snp.bottom).offset(-12)
            maker.height.equalTo(174)
        }
    }
    
    @objc
    private func createKeyButtonDidClicked() {
        delegate?.introWizardViewController?(self, willDismissAt: currentIndex)
        dismiss(animated: true) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.createKeyButtonDidClicked?(strongSelf)
        }
    }
    
    @objc
    private func importKeyButtonDidClicked() {
        delegate?.introWizardViewController?(self, willDismissAt: currentIndex)
        dismiss(animated: true) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.importKeyButtonDidClicked?(strongSelf)
        }
    }
    
    @objc
    private func notNowKeyButtonDidClicked() {
        delegate?.introWizardViewController?(self, willDismissAt: currentIndex)
        dismiss(animated: true) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.nowNowButtonDidClicked?(strongSelf)
        }
    }
}
