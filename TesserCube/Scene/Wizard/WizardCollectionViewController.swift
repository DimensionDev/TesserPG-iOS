//
//  WizardCollectionViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-5-7.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

protocol WizardCollectionViewControllerDelegate: class {
    func wizardCollectionViewController(_ collectionView: WizardCollectionViewController, numberOfPages count: Int)
    func wizardCollectionViewController(_ collectionView: WizardCollectionViewController, didScrollToPage page: Int)
    func wizardCollectionViewController(_ collectionView: WizardCollectionViewController, scrollViewDidScroll scrollView: UIScrollView)
}

class WizardCollectionViewController: UIViewController {

    lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.minimumLineSpacing = 0
        return collectionViewLayout
    }()

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: collectionViewLayout)
        collectionView.register(WizardCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: WizardCollectionViewCell.self))
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()

    weak var delegate: WizardCollectionViewControllerDelegate?

}

extension WizardCollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        collectionView.delegate = self
        collectionView.dataSource = self
    }

}

// MARK: - UICollectionViewDataSource
extension WizardCollectionViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = WizardCollectionViewController.Page.allCases.count
        delegate?.wizardCollectionViewController(self, numberOfPages: count)
        return count
    }

    // swiftlint:disable force_cast
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: WizardCollectionViewCell.self), for: indexPath) as! WizardCollectionViewCell
        cell.page = WizardCollectionViewController.Page.allCases[indexPath.item]
        return cell
    }
    // swiftlint:enable force_cast

}

// MARK: - UICollectionViewDelegate
extension WizardCollectionViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.bounds.width, height: view.bounds.height)
    }


    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.wizardCollectionViewController(self, scrollViewDidScroll: scrollView)

        let center = CGPoint(x: scrollView.contentOffset.x + 0.5 * scrollView.bounds.width, y: 0.5 * scrollView.bounds.height)
        if let indexPath = collectionView.indexPathForItem(at: center) {
            delegate?.wizardCollectionViewController(self, didScrollToPage: indexPath.item)
        }
    }

}

extension WizardCollectionViewController {

    enum Page: CaseIterable {
        case importPublicKeys
        case typeAndEncrypt
        case copyToInterpret

        var before: Page? {
            let allCases = Page.allCases
            guard let index = allCases.firstIndex(of: self), index > allCases.startIndex else {
                return nil
            }

            let beforeIndex = allCases.index(before: index)
            return allCases[beforeIndex]
        }

        var after: Page? {
            let allCases = Page.allCases
            guard let index = allCases.firstIndex(of: self), index < allCases.endIndex - 1 else {
                return nil
            }

            let afterIndex = allCases.index(after: index)
            return allCases[afterIndex]
        }

        var image: UIImage {
            switch self {
            case .importPublicKeys:     return Asset.wizardImportPublicKeys.image
            case .typeAndEncrypt:       return Asset.wizardTypeAndEncrypt.image
            case .copyToInterpret:      return Asset.wizardCopyToInterpret.image
            }
        }

        var titleText: String {
            switch self {
            case .importPublicKeys:     return L10n.WizardCollectionViewController.Page.ImportPublicKeys.titleText
            case .typeAndEncrypt:       return L10n.WizardCollectionViewController.Page.TypeAndEncrypt.titleText
            case .copyToInterpret:      return L10n.WizardCollectionViewController.Page.CopytoInterpret.titleText
            }
        }

        var detailText: String {
            switch self {
            case .importPublicKeys:     return L10n.WizardCollectionViewController.Page.ImportPublicKeys.detailText
            case .typeAndEncrypt:       return L10n.WizardCollectionViewController.Page.TypeAndEncrypt.detailText
            case .copyToInterpret:      return L10n.WizardCollectionViewController.Page.CopytoInterpret.detailText
            }
        }
    }

}
