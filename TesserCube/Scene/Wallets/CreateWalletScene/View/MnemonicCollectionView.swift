//
//  MnemonicCollectionView.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-1-17.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

public class MnemonicCollectionView: UICollectionView {

    public static let margin                  : CGFloat = 10
    public static let minimumLineSpacing      : CGFloat = 10
    public static let minimumInteritemSpacing : CGFloat = 10

    public static var height: CGFloat {
        return margin + 4 * MnemonicCollectionViewCell.height + 3 * minimumLineSpacing + margin
    }

    let viewModel: MnemonicCollectionViewModel
    var viewModelAsDelegate: UICollectionViewDelegate? {
        return viewModel as? UICollectionViewDelegate
    }

    init(viewModel: MnemonicCollectionViewModel) {
        self.viewModel = viewModel

        let layout                     = UICollectionViewFlowLayout()
        layout.minimumLineSpacing      = MnemonicCollectionView.minimumLineSpacing
        layout.minimumInteritemSpacing = MnemonicCollectionView.minimumInteritemSpacing

        super.init(frame: .zero, collectionViewLayout: layout)

        let margin = MnemonicCollectionView.margin
        contentInset = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        isScrollEnabled = false

        allowsMultipleSelection = true

        backgroundColor = UIColor.black.withAlphaComponent(0.02)    // magic number from sketch
        layer.cornerRadius = 5
        layer.masksToBounds = true

        dataSource      = viewModel
        delegate        = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: - UICollectionViewDelegate
extension MnemonicCollectionView: UICollectionViewDelegate {

    // Managing the Selected Cells

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return viewModelAsDelegate?.collectionView?(collectionView, shouldSelectItemAt: indexPath) ?? false
    }

    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return viewModelAsDelegate?.collectionView?(collectionView, shouldDeselectItemAt: indexPath) ?? false
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModelAsDelegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        viewModelAsDelegate?.collectionView?(collectionView, didDeselectItemAt: indexPath)
    }

    // Managing Cell Highlighting

    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return viewModelAsDelegate?.collectionView?(collectionView, shouldHighlightItemAt: indexPath) ?? false
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension MnemonicCollectionView: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let width = (collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right - 2 * layout.minimumInteritemSpacing) / 3
        let size = CGSize(width: floor(width), height: MnemonicCollectionViewCell.height)
        return size
    }

}

