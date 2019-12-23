//
//  WalletPageTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-17.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol WalletPageTableViewCellDelegate: class {
    func walletPageTableViewCell(_ cell: WalletPageTableViewCell, didUpdateCurrentPage index: Int)
}

final class WalletPageTableViewCell: UITableViewCell {
    
    var disposeBag = DisposeBag()
    weak var delegate: WalletPageTableViewCellDelegate?
    
    let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    let pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = 1
        pageControl.currentPage = 0
        pageControl.hidesForSinglePage = true
        pageControl.pageIndicatorTintColor = ._secondaryLabel
        pageControl.currentPageIndicatorTintColor = ._label
        return pageControl
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        delegate = nil
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension WalletPageTableViewCell {
    
    private func _init() {
        // Prevent wallet card shadow clipped
        pageViewController.view.clipsToBounds = false
        for view in pageViewController.view.subviews {
            view.clipsToBounds = false
        }
        
        // Layout page control
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pageControl)
        NSLayoutConstraint.activate([
            pageControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pageControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            pageControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            pageControl.heightAnchor.constraint(equalToConstant: 20),
        ])

        // Bind page view controller delegate to updaet page control
        pageViewController.delegate = self
    }
    
}

// MAKR: - UIPageViewControllerDelegate
extension WalletPageTableViewCell: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard pageViewController === self.pageViewController else {
            return
        }
        
        guard finished else {
            return
        }
        
        guard let firstWalletCardViewController = pageViewController.viewControllers?.first as? WalletCardViewController else {
            return
        }
        
        let index = firstWalletCardViewController.index
        delegate?.walletPageTableViewCell(self, didUpdateCurrentPage: index)
    }
    
}
