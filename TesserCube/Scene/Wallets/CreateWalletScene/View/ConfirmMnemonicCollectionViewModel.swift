//
//  ConfirmMnemonicCollectionViewModel.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-8.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final public class ConfirmMnemonicCollectionViewModel: MnemonicCollectionViewModel {

    enum CollectionViewTag: Int {
        case upper = 100
        case lower = 101
    }

    override var collectionView: UICollectionView? {
        get { return upperSelectedMnemonicCollectionView }
        set { upperSelectedMnemonicCollectionView = newValue }
    }
    var upperSelectedMnemonicCollectionView: UICollectionView? {
        didSet {
            upperSelectedMnemonicCollectionView?.tag = CollectionViewTag.upper.rawValue
            upperSelectedMnemonicCollectionView?.register(MnemonicCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: MnemonicCollectionViewCell.self))
        }
    }
    var lowerSelectMnemonicCollectionView: UICollectionView? {
        didSet {
            lowerSelectMnemonicCollectionView?.tag = CollectionViewTag.lower.rawValue
            lowerSelectMnemonicCollectionView?.register(MnemonicCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: MnemonicCollectionViewCell.self))
        }
    }

    var rightOrderMnemonic: [String]
    var mnemonic: [String]
    var selectedMnemonic: [String] = [] {
        didSet {
            isComplete.accept(selectedMnemonic.count == mnemonic.count)
            isConfimed.accept(selectedMnemonic == rightOrderMnemonic)
            print(selectedMnemonic, rightOrderMnemonic)
        }
    }

    // Output
    var isComplete = BehaviorRelay(value: false)
    var isConfimed = BehaviorRelay(value: false)

    public init(mnemonic: [String]) {
        assert(mnemonic.count == 12)
        rightOrderMnemonic = mnemonic

        #if DEBUG
        self.mnemonic = mnemonic
        #else
        self.mnemonic = mnemonic.shuffled()
        #endif

        super.init()


    }

}

extension ConfirmMnemonicCollectionViewModel {

    public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView.tag {
        case CollectionViewTag.upper.rawValue:
            return selectedMnemonic.count
        case CollectionViewTag.lower.rawValue:
            return 4 * 3    // 4 row * 3 col
        default:
            fatalError()
        }

    }

    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! MnemonicCollectionViewCell

        switch collectionView.tag {
        case CollectionViewTag.upper.rawValue:
            cell.wordTextField.text = selectedMnemonic[indexPath.item]
        case CollectionViewTag.lower.rawValue:
            cell.wordTextField.text = mnemonic[indexPath.item]
        default:
            assertionFailure()
        }

        cell.wordTextField.isEnabled = false
        return cell
    }

}

// MARK: - UICollectionViewDelegate
extension ConfirmMnemonicCollectionViewModel: UICollectionViewDelegate {

    // Managing the Selected Cells

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        switch collectionView.tag {
        case CollectionViewTag.upper.rawValue:
            return true
        case CollectionViewTag.lower.rawValue:
            let word = mnemonic[indexPath.item]
            return !selectedMnemonic.contains(word)
        default:
            assertionFailure()
            return false
        }
    }

    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        switch collectionView.tag {
        case CollectionViewTag.upper.rawValue:
            return true
        case CollectionViewTag.lower.rawValue:
            return false
        default:
            assertionFailure()
            return false
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView.tag {
        case CollectionViewTag.upper.rawValue:
            let removeWord = selectedMnemonic[indexPath.item]
            selectedMnemonic.remove(at: indexPath.item)
            upperSelectedMnemonicCollectionView?.reloadData()
            for (i, word) in mnemonic.enumerated() where word == removeWord {
                lowerSelectMnemonicCollectionView?.deselectItem(at: IndexPath(item: i, section: 0), animated: true)
            }
        case CollectionViewTag.lower.rawValue:
            selectedMnemonic.append(mnemonic[indexPath.row])
            upperSelectedMnemonicCollectionView?.reloadData()

        default:
            assertionFailure()
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        switch collectionView.tag {
        case CollectionViewTag.upper.rawValue:
            break
        case CollectionViewTag.lower.rawValue:
            break
        default:
            assertionFailure()
        }
    }

    // Managing Cell Highlighting

    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        switch collectionView.tag {
        case CollectionViewTag.upper.rawValue:
            return true
        case CollectionViewTag.lower.rawValue:
            let word = mnemonic[indexPath.row]
            return !selectedMnemonic.contains(word)
        default:
            assertionFailure()
        }

        return false
    }

}

