//
//  MnemonicCollectionViewViewModel.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-1-18.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

public class MnemonicCollectionViewModel: NSObject {

    weak var collectionView: UICollectionView? {
        didSet {
            collectionView?.register(MnemonicCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: MnemonicCollectionViewCell.self))
        }
    }

}

// MARK: - UICollectionViewDataSource
extension MnemonicCollectionViewModel: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4 * 3    // 4 row * 3 col
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MnemonicCollectionViewCell.self), for: indexPath) as! MnemonicCollectionViewCell
        return cell
    }

}

