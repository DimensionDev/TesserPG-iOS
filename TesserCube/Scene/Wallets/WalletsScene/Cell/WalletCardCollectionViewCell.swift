//
//  WalletCardCollectionViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-25.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class WalletCardCollectionViewCell: UICollectionViewCell {

    var disposeBag = DisposeBag()

    static let cardVerticalMargin: CGFloat = 8
    let walletCardView = WalletCardView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
        
        walletCardView.headerLabel.text = "****"
        walletCardView.captionLabel.text = "********************\n********************"
        walletCardView.balanceLabel.text = "Balance:"
        walletCardView.balanceAmountLabel.text = "- ETH"
    }
    
}

extension WalletCardCollectionViewCell {
    
    private func _init() {
        // Setup appearance
        clipsToBounds = false
        
        walletCardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(walletCardView)
        NSLayoutConstraint.activate([
            walletCardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: WalletCardCollectionViewCell.cardVerticalMargin),
            walletCardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: walletCardView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: walletCardView.bottomAnchor, constant: WalletCardCollectionViewCell.cardVerticalMargin),
        ])
    }
    
}

extension WalletCardCollectionViewCell {
    
    
}
