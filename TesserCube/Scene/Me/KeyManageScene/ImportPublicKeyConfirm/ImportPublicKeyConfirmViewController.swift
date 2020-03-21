//
//  ImportPublicKeyConfirmViewController.swift
//  TesserCube
//
//  Created by jk234ert on 2019/7/3.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import SnapKit
import SwifterSwift
import RxCocoa
import RxSwift
import ConsolePrint
import DMSGoPGP

final class ImportPublicKeyConfirmViewModel {
    
    let disposeBag = DisposeBag()
    
    // Input
    let tcKey: TCKey
    
    // Output
    let isKeyValid: BehaviorRelay<Bool>
    let keyStatus = BehaviorRelay<KeyStatus>(value: .new)   // default set to .new status
    
    init(tcKey: TCKey) {
        self.tcKey = tcKey
        self.isKeyValid = BehaviorRelay(value: tcKey.isValid)
        
        ProfileService.default.keys.asDriver()
            .map { keys -> KeyStatus in
                let existedKeyLongIdentifiers = keys.map { $0.longIdentifier }
                let newEntities = tcKey.entities
                let newLongIdentifiers = newEntities.compactMap { $0.primaryKey?.keyIdString() }
                let filteredLongIdentifiers = newLongIdentifiers.filter { !existedKeyLongIdentifiers.contains($0) }
                
                if filteredLongIdentifiers.count == 0 {
                    return .existed
                } else if newLongIdentifiers.count == filteredLongIdentifiers.count {
                    return .new
                } else {
                    let new = filteredLongIdentifiers.count
                    let existed = newLongIdentifiers.count - new
                    return .partial(new: new, existed: existed)
                }
            }
            .drive(keyStatus)
            .disposed(by: disposeBag)
    }
    
}

extension ImportPublicKeyConfirmViewModel {
    
    enum KeyStatus {
        case new
        case partial(new: Int, existed: Int)
        case existed
    }
    
}

class ImportPublicKeyConfirmViewController: TCBaseViewController {
    
    let disposeBag = DisposeBag()
    var viewModel: ImportPublicKeyConfirmViewModel!
    
    let cardHeight: CGFloat = 106
    
    var cardCollectionView: UICollectionView = {
        let layout = CollectionViewFlowLayoutCenterItem()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(nibWithCellClass: ConfirmContactCell.self)
        return collectionView
    }()
    
    private func createTitleLabel(title: String) -> UILabel {
        let label = UILabel(frame: .zero)
        label.text = title
        label.font = FontFamily.SFProText.regular.font(size: 14)
        label.numberOfLines = 1
        return label
    }
    
    private lazy var integritylabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = FontFamily.SFProText.regular.font(size: 17)
        return label
    }()
    
    private lazy var validitylabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = FontFamily.SFProText.regular.font(size: 17)
        label.textColor = .systemGreen
        return label
    }()
    
    private lazy var availabilitylabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = FontFamily.SFProText.regular.font(size: 17)
        return label
    }()
    
    private lazy var iconlabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 50)
        label.text = "🎉"
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    private lazy var successlabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = FontFamily.SFProText.regular.font(size: 20)
        label.isHidden = true
        label.text = L10n.ImportPublicKeyConfirmViewController.Label.contactsAddedSuccessfully
        label.textAlignment = .center
        return label
    }()
    
    private lazy var importButton: TCActionButton = {
        let button = TCActionButton(frame: .zero)
        button.color = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.setTitle(L10n.MeViewController.Action.Button.importKey, for: .normal)
        return button
    }()
    
    override func configUI() {
        super.configUI()
        title = L10n.ImportPublicKeyConfirmViewController.Title.newContact
        importButton.addTarget(self, action: #selector(importButtonDidClicked), for: .touchUpInside)
        
        view.addSubview(cardCollectionView)
        cardCollectionView.delegate = self
        cardCollectionView.dataSource = self
        
        let validityTitleLabel = createTitleLabel(title: L10n.ContactDetailViewController.Label.validity)
        view.addSubview(validityTitleLabel)
        view.addSubview(validitylabel)
        
        let availabilityTitleLabel = createTitleLabel(title: L10n.ImportPublicKeyConfirmViewController.Label.availability)
        view.addSubview(availabilityTitleLabel)
        view.addSubview(availabilitylabel)
        
        view.addSubview(iconlabel)
        view.addSubview(successlabel)
        
        view.addSubview(importButton)
        
        cardCollectionView.snp.makeConstraints { maker in
            maker.top.equalTo(view.snp.topMargin).offset(20)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(106)
        }
    
        validityTitleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(cardCollectionView.snp.bottom).offset(30)
            maker.leading.equalTo(view.safeAreaLayoutGuide).offset(16)
            maker.trailing.equalTo(view.safeAreaLayoutGuide).offset(-16)
        }
        
        validitylabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(validityTitleLabel)
            maker.top.equalTo(validityTitleLabel.snp.bottom).offset(2)
        }
        
        availabilityTitleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(validityTitleLabel)
            maker.top.equalTo(validitylabel.snp.bottom).offset(17)
        }
        
        availabilitylabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(validityTitleLabel)
            maker.top.equalTo(availabilityTitleLabel.snp.bottom).offset(2)
        }
        
        importButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(view.layoutMarginsGuide)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            maker.height.equalTo(50)
        }
        
        successlabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(validityTitleLabel)
            maker.bottom.equalTo(importButton.snp.top).offset(-30)
        }
        
        iconlabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(validityTitleLabel)
            maker.bottom.equalTo(successlabel.snp.top).offset(-10)
        }
        
        // Bind viewModel
        viewModel.isKeyValid.asDriver()
            .drive(onNext: { [weak self] isValid in
                guard let `self` = self else { return }
                
                self.validitylabel.text = isValid ? L10n.ContactDetailViewController.Label.valid : L10n.ContactDetailViewController.Label.invalid
                self.validitylabel.textColor = isValid ? .systemGreen : .systemRed
                
            })
            .disposed(by: disposeBag)
        
        viewModel.keyStatus.asDriver()
            .drive(onNext: { [weak self] keyStatus in
                guard let `self` = self else { return }
                
                switch keyStatus {
                case .new:
                    self.iconlabel.isHidden = true
                    self.successlabel.isHidden = true
                    self.importButton.color = .systemBlue
                    self.importButton.setTitleColor(.white, for: .normal)
                    self.importButton.setTitle(L10n.ImportPublicKeyConfirmViewController.Button.addContact, for: .normal)
                    self.availabilitylabel.text = L10n.ImportPublicKeyConfirmViewController.Label.notAdded
                    
                case let .partial(new, _):
                    self.iconlabel.isHidden = true
                    self.successlabel.isHidden = true
                    self.importButton.color = .systemBlue
                    self.importButton.setTitleColor(.white, for: .normal)
                    self.importButton.setTitle(L10n.ImportPublicKeyConfirmViewController.Button.addContact, for: .normal)
                    if new == 1 {
                        self.availabilitylabel.text = L10n.ImportPublicKeyConfirmViewController.Label.isPartialAddedOneKeyNew
                    } else {
                        self.availabilitylabel.text = L10n.ImportPublicKeyConfirmViewController.Label.isPartialAddedMultipleKeysNew(new)
                    }
                    
                case .existed:
                    self.iconlabel.isHidden = false
                    self.successlabel.isHidden = false
                    self.importButton.color = ._secondarySystemBackground
                    self.importButton.setTitleColor(._label, for: .normal)
                    self.importButton.setTitle(L10n.ImportPublicKeyConfirmViewController.Button.close, for: .normal)
                    self.availabilitylabel.text = L10n.ImportPrivateKeyConfirmViewController.Label.isAdded
                }
            })
            .disposed(by: disposeBag)
    }
    
    @objc
    func importButtonDidClicked() {
        switch viewModel.keyStatus.value {
        case .new, .partial:
            ProfileService.default.addKey(viewModel.tcKey, passphrase: nil) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showSimpleAlert(title: L10n.Common.Alert.error, message: error.localizedDescription)
                    } else {
                        // do nothing
                    }
                }
            }
            
        case .existed:
            // dismissToRoot
            navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc
    func dismissToRoot() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension ImportPublicKeyConfirmViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.tcKey.userIDs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: ConfirmContactCell.self, for: indexPath)
        
        cell.keyValue = .TCKey(value: viewModel.tcKey)
        cell.userID = viewModel.tcKey.userIDs[indexPath.row].first
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let count = viewModel.tcKey.userIDs.count
        if count > 1 {
            return CGSize(width: SwifterSwift.screenWidth - 16 - 66, height: cardHeight)
        } else {
            return CGSize(width: SwifterSwift.screenWidth - 16 * 2, height: cardHeight)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}

class CollectionViewFlowLayoutCenterItem: UICollectionViewFlowLayout {
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint,
                                      withScrollingVelocity velocity: CGPoint) -> CGPoint {
        
        var result = super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        
        guard let collectionView = collectionView else {
            return result
        }
        
        let halfWidth = 0.5 * collectionView.bounds.size.width
        let proposedContentCenterX = result.x + halfWidth
        
        let targetRect = CGRect(origin: result, size: collectionView.bounds.size)
        let layoutAttributes = layoutAttributesForElements(in: targetRect)?
            .filter { $0.representedElementCategory == .cell }
            .sorted { abs($0.center.x - proposedContentCenterX) < abs($1.center.x - proposedContentCenterX) }
        
        guard let closest = layoutAttributes?.first else {
            return result
        }
        
        result = CGPoint(x: closest.center.x - halfWidth, y: proposedContentOffset.y)
        return result
    }
}
