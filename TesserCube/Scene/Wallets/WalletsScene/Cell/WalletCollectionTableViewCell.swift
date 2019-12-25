//
//  WalletCollectionTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-17.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

// Wallet collection view in table view cell
final class WalletCollectionTableViewCell: UITableViewCell {
    
    static let cellHeight: CGFloat = 120.0
    static let collectionViewTag = 120
    
    var disposeBag = DisposeBag()
    
    let collectionViewLayout: UICollectionViewFlowLayout = {
        let collectionFlowLayout = UICollectionViewFlowLayout()
        // wallet card section scroll horizontal
        collectionFlowLayout.scrollDirection = .horizontal
        return collectionFlowLayout
    }()
        
    private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.register(WalletCardCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: WalletCardCollectionViewCell.self))
        collectionView.backgroundColor = .clear
        collectionView.clipsToBounds = false
        // enable paging
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.tag = WalletCollectionTableViewCell.collectionViewTag
        return collectionView
    }()
    
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

extension WalletCollectionTableViewCell {
    
    private func _init() {
        // Layout wallet card collection view 
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: WalletCollectionTableViewCell.cellHeight + 2 * WalletCardCollectionViewCell.cardVerticalMargin),
        ])
        
        // Layout page control
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pageControl)
        NSLayoutConstraint.activate([
            pageControl.topAnchor.constraint(equalTo: collectionView.bottomAnchor),
            pageControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pageControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            pageControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            pageControl.heightAnchor.constraint(equalToConstant: 20),
        ])
    }
    
}
