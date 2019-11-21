//
//  RecipientContactPickerView.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-3-25.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SnapKit
import AlignedCollectionViewFlowLayout
import DeepDiff

import RxSwift
import RxCocoa

final class RecipientContactPickerViewModel: NSObject {

    let disposeBag = DisposeBag()

    // Input
    let tags = BehaviorRelay<[KeyBridge]>(value: [])
    let diff: Observable<([KeyBridge], [KeyBridge])>

    // For DeepDiff safe updateData
    var _tags: [KeyBridge] = []

    override init() {
        diff = BehaviorRelay.zip(tags, tags.skip(1)) { ($0, $1) }
        super.init()
    }

}

extension RecipientContactPickerViewModel: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _tags.count
        // TODO: addional text input cell
        // return contacts.count + 1
    }

    // swiftlint:disable force_cast
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.row {
        case 0..<_tags.count:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing:
                ContactPickerTagCollectionViewCell.self), for: indexPath) as! ContactPickerTagCollectionViewCell
            let tag = _tags[indexPath.row]
            cell.nameLabel.text = tag.name
            cell.shortID = tag.shortID.separate(every: 4, with: "\n")
            cell.isInvalid = tag.contact == nil
            return cell

        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ContactPickerTextFieldCollectionViewCell.self), for: indexPath) as! ContactPickerTextFieldCollectionViewCell
            return cell
        }

    }
    // swiftlint:enable force_cast

}

// TODO: fix scroll view not set bottom inset when keyboard appear after tap tag cell
final class RecipientContactPickerView: UIView {

    let disposeBag = DisposeBag()

    static let leadingMargin: CGFloat = 20
    static let verticalMargin: CGFloat = 6

    private let paddingView = UIView()

    weak var contactPickerTagCollectionViewCellDelegate: ContactPickerTagCollectionViewCellDelegate?

    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = ._secondaryLabel
        label.font = FontFamily.SFProText.regular.font(size: 15)
        return label
    }()

    lazy var contactCollectionView: UICollectionView = {
        let layout = AlignedCollectionViewFlowLayout(horizontalAlignment: .left, verticalAlignment: .top)
        layout.estimatedItemSize = CGSize(width: 100, height: 50)

        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), collectionViewLayout: layout)
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = .clear
        collectionView.register(ContactPickerTagCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ContactPickerTagCollectionViewCell.self))
        collectionView.register(ContactPickerTextFieldCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ContactPickerTextFieldCollectionViewCell.self))

        return collectionView
    }()
    lazy var contactCollectionViewHeightLayoutConstraint = contactCollectionView.heightAnchor.constraint(equalToConstant: 0)

    let addButton: UIButton = {
        let button = UIButton(type: .contactAdd)
        return button
    }()

    let viewModel = RecipientContactPickerViewModel()

    weak var pickContactsDelegate: (PickContactsDelegate & UIViewController)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _init()
    }

    private func _init() {
        backgroundColor = .clear
        layoutMargins = UIEdgeInsets(top: 8, left: RecipientContactPickerView.leadingMargin, bottom: 8, right: 20)

        paddingView.isHidden = true
        addSubview(paddingView)
        paddingView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.equalToSuperview()
            maker.height.equalTo(ContactPickerTagCollectionViewCell.tagHeight + 2 * RecipientContactPickerView.verticalMargin).priority(999)
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(layoutMarginsGuide)
            maker.centerY.equalTo(paddingView.snp.centerY)
        }
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        addSubview(addButton)
        addButton.snp.makeConstraints { maker in
            maker.top.equalTo(paddingView.snp.top)
            maker.trailing.equalToSuperview()
            maker.bottom.equalTo(paddingView.snp.bottom)
            maker.width.equalTo(addButton.snp.height)
        }

        addSubview(contactCollectionView)
        contactCollectionView.snp.makeConstraints { maker in
            maker.top.equalTo(snp.top).offset(RecipientContactPickerView.verticalMargin)
            maker.leading.equalTo(titleLabel.snp.trailing).offset(14)
            maker.trailing.equalTo(addButton.snp.leading)
        }
        contactCollectionViewHeightLayoutConstraint.priority = UILayoutPriority(999)
        contactCollectionViewHeightLayoutConstraint.isActive = true

        let separatorView = UIView()
        addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.top.equalTo(contactCollectionView.snp.bottom).offset(6)
            maker.leading.equalTo(snp.leadingMargin)
            maker.trailing.bottom.equalToSuperview()
            maker.height.equalTo(0.3)
        }

        separatorView.backgroundColor = .separator
        addButton.addTarget(self, action: #selector(RecipientContactPickerView.addButtonPressed(_:)), for: .touchUpInside)
        contactCollectionView.delegate = self
        contactCollectionView.dataSource = viewModel

        viewModel.diff.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] old, new in
                guard let `self` = self else { return }
                let changes = diff(old: old, new: new)
                self.contactCollectionView.reload(changes: changes, section: 0, updateData: {
                    self.viewModel._tags = new
                }, completion: { _ in
                    self.setNeedsLayout()
                    self.layoutIfNeeded()
                })
            })
            .disposed(by: disposeBag)
    }

    override func layoutSubviews() {
        contactCollectionView.invalidateIntrinsicContentSize()
        contactCollectionView.setNeedsLayout()
        contactCollectionView.layoutIfNeeded()
        super.layoutSubviews()

        contactCollectionViewHeightLayoutConstraint.constant = max(contactCollectionView.contentSize.height, paddingView.frame.height - 2 * RecipientContactPickerView.verticalMargin)
    }
    
}

private extension RecipientContactPickerView {

    @objc func addButtonPressed(_ sender: UIButton) {
        // FIXME: filter out contact without attached public key
        let selectedContacts = viewModel.tags.value.compactMap { $0.contact }
        #if !TARGET_IS_EXTENSION
        Coordinator.main.present(scene: .pickContacts(delegate: pickContactsDelegate, selectedContacts: selectedContacts), from: pickContactsDelegate, transition: .modal, completion: nil)
        #else
        let vc = ContactsListViewController()
        vc.isPickContactMode = true
        vc.delegate = pickContactsDelegate
        vc.preSelectedContacts = selectedContacts
        vc.hidesBottomBarWhenPushed = true
        pickContactsDelegate?.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        #endif
    }

}

// MARK: - UICollectionViewDelegate
extension RecipientContactPickerView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ContactPickerTagCollectionViewCell {
            cell.delegate = self
        }
    }
    
}

// MARK: - ContactPickerTagCollectionViewCellDelegate
extension RecipientContactPickerView: ContactPickerTagCollectionViewCellDelegate {

    func contactPickerTagCollectionViewCell(_ cell: ContactPickerTagCollectionViewCell, didDeleteBackward: Void) {
        contactPickerTagCollectionViewCellDelegate?.contactPickerTagCollectionViewCell(cell, didDeleteBackward: ())
    }

}
