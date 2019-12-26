//
//  ImportMnemonicCollectionViewModel.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-8.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import UIKit
import RxSwift
import RxCocoa
import DMS_HDWallet_Cocoa

protocol ImportMnemonicCollectionViewModelDelegate: class {
    func importMnemonicCollectionViewModel(_ vieModel: ImportMnemonicCollectionViewModel, lastTextFieldReturn textField: UITextField)
}

class ImportMnemonicCollectionViewModel: MnemonicCollectionViewModel {

    enum Error: Swift.Error {
        case invalidMnemonic
        case wrongPassphrase
        case unknown
        case retrieve
    }

    let disposeBag = DisposeBag()
    weak var delegate: ImportMnemonicCollectionViewModelDelegate?

    private var wordsDict: [Int: String] = [:] {
        didSet {
            os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, String(describing: mnemonic))

            isComplete.accept(mnemonic.count == 12)
        }
    }
    var mnemonic: [String] {
        return Array(0..<12)
            .map { wordsDict[$0] ?? nil }
            .compactMap { $0 }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    typealias Input = (mnemonic: [String], passphrase: String)
    // Input
    // var input = BehaviorRelay<Input>(value: (mnemonic: [], passphrase: ""))

    // Output
    let isComplete = BehaviorRelay(value: false)
//    let isRetrieving: Driver<Bool>
//    let profile = BehaviorRelay<Result<Profile>?>(value: nil)

    override init() {
//        let activityIndicator = ActivityIndicator()
//        isRetrieving = activityIndicator.asDriver()

        super.init()

//        input.asDriver()
//            .skip(1)
//            .flatMapLatest { input -> Driver<Result<Profile>?> in
//                let (mnemonic, inputPassphrase) = input
//                let passphrase = inputPassphrase.trimmingCharacters(in: .whitespacesAndNewlines)
//                guard !passphrase.isEmpty else {
//                    return .just(.failure(Error.wrongPassphrase))
//                }
//
//                do {
//                    let wallet = try HDWallet(mnemonic: mnemonic, passphrase: passphrase, network: .mainnet(.ether))
//                    let publicKey = try wallet.publicKey()
//                    return GazettePrintingService.shared.retrieve(publicKey: publicKey).asObservable()
//                        .trackActivity(activityIndicator)
//                        .map { status -> Result<Profile>? in
//                            guard status.status == "Retrieve successful.", let username = status.username else {
//                                consolePrint(status)
//                                return .failure(Error.retrieve)
//                            }
//                            return .success(Profile(mnemonic: mnemonic, passphrase: passphrase, nickname: username, avatar: nil))
//                        }
//                        .asDriver(onErrorJustReturn: .failure(Error.retrieve))
//                } catch HDWalletError.invalidMnemonic {
//                    return .just(.failure(Error.invalidMnemonic))
//                } catch let error as HDWalletError {
//                    assertionFailure(error.localizedDescription)
//                    return .just(.failure(Error.invalidMnemonic))
//                } catch {
//                    return .just(.failure(Error.unknown))
//                }
//            }
//            .drive(profile)
//            .disposed(by: disposeBag)

//        profile.asDriver()
//            .drive(onNext: { result in
//                guard let result = result else { return }
//                switch result {
//                case .success(let profile):
//                    GazetteProfileService.default.status.accept(.profile(profile))
//                default:
//                    return
//                }
//            })
//            .disposed(by: disposeBag)

//        NotificationCenter.default.addObserver(self, selector: #selector(ImportMnemonicCollectionViewModel.keyboardWillHideNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

//    @objc private func keyboardWillHideNotification(_ notification: Notification) {
//        Array(0..<12)
//            .map { IndexPath(item: $0, section: 0) }
//            .compactMap { collectionView?.cellForItem(at: $0) as? KeygenRegisterMnemonicCollectionViewCell }
//            .compactMap { ($0.wordTextField.tag, $0.wordTextField.text) }
//            .forEach { tag, text in
//                wordsDict[tag] = text
//            }
//    }

}

extension ImportMnemonicCollectionViewModel {

    public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4 * 3    // 4 row * 3 col
    }

    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! MnemonicCollectionViewCell
        cell.wordTextField.placeholder = "\(indexPath.item + 1)"
        cell.wordTextField.tag = indexPath.item
        cell.wordTextField.keyboardType = .asciiCapable
        cell.wordTextField.autocapitalizationType = .none
        cell.wordTextField.autocorrectionType = .no
        cell.wordTextField.delegate = self
        cell.wordTextField.filterStrings(Mnemonic.words)
        cell.wordTextField.theme.font = FontFamily.SFProText.regular.font(size: 15.0)
        cell.wordTextField.theme.cellHeight = 50
        cell.wordTextField.maxNumberOfResults = 5
        cell.wordTextField.comparisonOptions = [.forcedOrdering, .anchored, .caseInsensitive]
        cell.wordTextField.itemSelectionHandler = { results, index in
            cell.wordTextField.text = results[index].title
            _ = cell.wordTextField.delegate?.textFieldShouldReturn?(cell.wordTextField)
        }
        
        cell.wordTextField.rx.text.asDriver()
            .drive(onNext: { [weak self] word in
                self?.wordsDict[indexPath.item] = word
            })
            .disposed(by: cell.disposeBag)
        
        return cell
    }

}

// MARK: - UITextFieldDelegate
extension ImportMnemonicCollectionViewModel: UITextFieldDelegate {

    public func textFieldDidEndEditing(_ textField: UITextField) {
//        let tag = textField.tag
//        consolePrint("\(tag): \(textField.text ?? "")")
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let tag = textField.tag
        let nextTag = tag + 1

        if nextTag < 12, let cell = collectionView?.cellForItem(at: IndexPath(item: nextTag, section: 0)) as? MnemonicCollectionViewCell {
            cell.wordTextField.becomeFirstResponder()
        } else {
            if let delegate = delegate {
                delegate.importMnemonicCollectionViewModel(self, lastTextFieldReturn: textField)
            } else {
                textField.resignFirstResponder()
            }
        }

        let text = textField.text ?? nil
        wordsDict[tag] = text

        return false
    }

}
