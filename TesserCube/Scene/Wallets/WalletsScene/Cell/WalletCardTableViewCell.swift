//
//  WalletCardTableViewCell.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-8.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift

final class WalletCardTableViewCell: UITableViewCell {

    var disposeBag = DisposeBag()

    static let cardVerticalMargin: CGFloat = 8
    let walletCardView = WalletCardView(frame: .zero)

    override func prepareForReuse() {
        super.prepareForReuse()

        disposeBag = DisposeBag()

        walletCardView.headerLabel.text = "****"
        walletCardView.captionLabel.text = "********************\n********************"
        walletCardView.balanceLabel.text = "Balance:"
        walletCardView.balanceAmountLabel.text = "- ETH"
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

    private func _init() {
        // Setup appearance
        clipsToBounds = false
        selectionStyle = .none
        backgroundColor = .clear

        walletCardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(walletCardView)
        NSLayoutConstraint.activate([
            walletCardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: WalletCardTableViewCell.cardVerticalMargin),
            walletCardView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: walletCardView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: walletCardView.bottomAnchor, constant: WalletCardTableViewCell.cardVerticalMargin),
            walletCardView.heightAnchor.constraint(equalToConstant: WalletCollectionTableViewCell.cellHeight),
        ])
    }

}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct WalletCardTableViewCell_Preview: PreviewProvider {
    static var previews: some View {
        UIViewPreview {
            return WalletCardTableViewCell()
        }
        .previewLayout(.fixed(width: 414, height: 122))
    }
}
#endif
