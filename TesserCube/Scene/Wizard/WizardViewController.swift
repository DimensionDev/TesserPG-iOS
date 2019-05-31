//
//  WizardViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-5-6.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class WizardViewController: TCBaseViewController {

    static let didPresentWizardKeyPath = "WizardViewController.didPresentWizard.v1"
    static var didPresentWizard: Bool {
        return UserDefaults.shared?.bool(forKey: didPresentWizardKeyPath) ?? false
    }

    static let imageTopMargin: CGFloat = 70
    static let imageBottomMargin: CGFloat = 60
    static let imageWidth: CGFloat = 161
    static let pageControlTopToImage: CGFloat = 230

    lazy var wizardCollectionViewController: WizardCollectionViewController = {
        let controller = WizardCollectionViewController()
        controller.delegate = self
        return controller
    }()

    lazy var imagePlaceholderView: UIView = {
        let placeholder = UIView()
        placeholder.clipsToBounds = false
        return placeholder
    }()

    lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.pageIndicatorTintColor = .lightGray
        pageControl.currentPageIndicatorTintColor = .black
        return pageControl
    }()
    var isLastPage: Bool = false {
        didSet {
            let title = isLastPage ? L10n.WizardViewController.Action.Button.startUsing : L10n.WizardViewController.Action.Button.next
            nextButton.setTitle(title, for: .normal)
        }
    }

    lazy var nextButton: TCActionButton = {
        let button = TCActionButton()
        button.color = Asset.shapeButtonBlue.color
        button.setTitleColor(.white, for: .normal)
        button.setTitle(L10n.WizardViewController.Action.Button.next, for: .normal)
        button.addTarget(self, action: #selector(WizardViewController.nextButtonDidPressed(_:)), for: .touchUpInside)
        return button
    }()

    let wizardImageViews: [UIImageView] = WizardCollectionViewController.Page.allCases.map { page in
        let imageView = UIImageView(image: page.image)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }

    lazy var wizardImageViewAnimator: UIViewPropertyAnimator = {
        wizardImageViews.dropFirst().forEach { imageView in
            imageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            imageView.alpha = 0
        }

        let duration = 0.33
        let animator = UIViewPropertyAnimator(duration: duration * Double(wizardImageViews.count), curve: .easeInOut) {
            // Add keyframe animation
            UIView.animateKeyframes(withDuration: 0.0, delay: 0.0, options: [], animations: {
                for (page, imageView) in self.wizardImageViews.enumerated() where page + 1 < self.wizardImageViews.count {
                    let nextImageView = self.wizardImageViews[page + 1]
                    UIView.addKeyframe(withRelativeStartTime: Double(page) * duration, relativeDuration: duration) {
                        imageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                        imageView.alpha = 0
                        nextImageView.transform = .identity
                        nextImageView.alpha = 1
                    }
                }

            }, completion: nil)

        }
        return animator
    }()

    override func configUI() {
        view.backgroundColor = Asset.sceneBackground.color

        addChild(wizardCollectionViewController)
        view.addSubview(wizardCollectionViewController.view)
        wizardCollectionViewController.didMove(toParent: self)

        imagePlaceholderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imagePlaceholderView)
        NSLayoutConstraint.activate([
            imagePlaceholderView.topAnchor.constraint(equalTo: wizardCollectionViewController.collectionView.layoutMarginsGuide.topAnchor, constant: WizardViewController.imageTopMargin),
            imagePlaceholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imagePlaceholderView.heightAnchor.constraint(equalToConstant: WizardViewController.imageWidth),
            imagePlaceholderView.widthAnchor.constraint(equalTo: imagePlaceholderView.heightAnchor, multiplier: 1.0),
        ])

        pageControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageControl)
        NSLayoutConstraint.activate([
            pageControl.topAnchor.constraint(equalTo: imagePlaceholderView.bottomAnchor, constant: WizardViewController.pageControlTopToImage),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])

        nextButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nextButton)
        let snapToSafeAreaGuideBottom = nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        snapToSafeAreaGuideBottom.priority = .defaultLow
        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 64),
            view.trailingAnchor.constraint(equalTo: nextButton.trailingAnchor, constant: 64),
            snapToSafeAreaGuideBottom,
            view.bottomAnchor.constraint(greaterThanOrEqualTo: nextButton.bottomAnchor, constant: 20),
        ])

        wizardImageViews.reversed().forEach { imageView in
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imagePlaceholderView.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: imagePlaceholderView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: imagePlaceholderView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: imagePlaceholderView.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: imagePlaceholderView.bottomAnchor),
            ])
        }

        // prepare for animation
        _ = wizardImageViewAnimator
    }
    
}

extension WizardViewController {

    @objc private func nextButtonDidPressed(_ sender: UIButton) {
        if isLastPage {
            UserDefaults.shared?.set(true, forKey: WizardViewController.didPresentWizardKeyPath)
            wizardImageViewAnimator.stopAnimation(true)
            Coordinator.main.present(scene: .main(message: nil), from: nil)
        } else {
            guard pageControl.currentPage + 1 < wizardCollectionViewController.collectionView.numberOfItems() else { return }
            wizardCollectionViewController.collectionView.scrollToItem(at: IndexPath(item: pageControl.currentPage + 1, section: 0), at: UICollectionView.ScrollPosition.centeredHorizontally, animated: true)
        }
    }
}

extension WizardViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        wizardCollectionViewController.view.frame = view.bounds
    }

}

// MARK: - WizardCollectionViewControllerDelegate
extension WizardViewController: WizardCollectionViewControllerDelegate {

    func wizardCollectionViewController(_ collectionView: WizardCollectionViewController, numberOfPages count: Int) {
        pageControl.numberOfPages = count
    }

    func wizardCollectionViewController(_ collectionView: WizardCollectionViewController, didScrollToPage page: Int) {
        pageControl.currentPage = page
        isLastPage = page == pageControl.numberOfPages - 1
    }

    func wizardCollectionViewController(_ collectionView: WizardCollectionViewController, scrollViewDidScroll scrollView: UIScrollView) {
        guard scrollView.contentSize.width > 0 else {
            return
        }
        let progress = scrollView.contentOffset.x / scrollView.contentSize.width
        wizardImageViewAnimator.fractionComplete = progress
    }

}
