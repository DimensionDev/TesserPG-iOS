//
//  WalletsViewModel.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-12.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import UIKit
import RxSwift
import RxCocoa

class WalletsViewModel: NSObject {
    
    let disposeBag = DisposeBag()

    // Input
    let walletModels = BehaviorRelay<[WalletModel]>(value: [])
    let redPackets = BehaviorRelay<[RedPacket]>(value: [])

    // Output
    let currentWalletModel = BehaviorRelay<WalletModel?>(value: nil)
    let currentWalletPageIndex = BehaviorRelay(value: 0)
    let filteredRedPackets = BehaviorRelay<[RedPacket]>(value: [])
    
    enum Section: Int, CaseIterable {
        case wallet
        case redPacket
    }

    override init() {
        super.init()
        
        currentWalletModel.asDriver()
            .drive(onNext: { walletModel in
                os_log("%{public}s[%{public}ld], %{public}s: currentWalletModel update to %s", ((#file as NSString).lastPathComponent), #line, #function, walletModel?.address ?? "nil")
            })
            .disposed(by: disposeBag)
        
        currentWalletPageIndex.asDriver()
            .drive(onNext: { index in
                os_log("%{public}s[%{public}ld], %{public}s: currentWalletPageIndex update to %s", ((#file as NSString).lastPathComponent), #line, #function, String(index))
            })
            .disposed(by: disposeBag)
        
        let currentWalletModelChanged = currentWalletModel.asDriver()
            .distinctUntilChanged { lhs, rhs -> Bool in return lhs?.address == rhs?.address }
        Driver.combineLatest(currentWalletModelChanged, redPackets.asDriver()) { currentWalletModel, redPackets -> [RedPacket] in
                guard let currentWalletModel = currentWalletModel else {
                    return []
                }
                
                return redPackets.filter { redPacket -> Bool in
                    return redPacket.sender_address == currentWalletModel.address ||
                           redPacket.claim_address == currentWalletModel.address
                }
            }
            .drive(filteredRedPackets)
            .disposed(by: disposeBag)
    }

}

// MARK: - UITableViewDataSource
extension WalletsViewModel: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        // Section:
        //  - 0: Wallet Section
        //  - 1: Red Packet Section
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section.allCases[section] {
        case .wallet:
            return 1
        case .redPacket:
            return filteredRedPackets.value.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

        let cell: UITableViewCell

        switch Section.allCases[indexPath.section] {
        case .wallet:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: WalletCollectionTableViewCell.self), for: indexPath) as! WalletCollectionTableViewCell
            
            _cell.collectionView.dataSource = self

            // Update collection view data source
            walletModels.asDriver()
                .drive(onNext: { [weak self] walletModels in
                    guard let `self` = self else { return }
                    _cell.collectionView.reloadData()
                    
                    guard !walletModels.isEmpty else {
                        self.currentWalletModel.accept(nil)
                        return
                    }
                    
                    let index = self.currentWalletPageIndex.value
                    if index < walletModels.count {
                        // index not move
                        self.currentWalletModel.accept(walletModels[index])
                    } else {
                        // index move 1 step before
                        self.currentWalletModel.accept(walletModels.last)
                        self.currentWalletPageIndex.accept(walletModels.count - 1)
                    }
                })
                .disposed(by: _cell.disposeBag)
        
            // setup page control
            walletModels.asDriver()
                .map { max($0.count, 1) }
                .drive(_cell.pageControl.rx.numberOfPages)
                .disposed(by: _cell.disposeBag)
            currentWalletPageIndex.asDriver()
                .drive(_cell.pageControl.rx.currentPage)
                .disposed(by: _cell.disposeBag)
            
            cell = _cell
            
        case .redPacket:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RedPacketCardTableViewCell.self), for: indexPath) as! RedPacketCardTableViewCell
            
            guard indexPath.row < filteredRedPackets.value.count, !filteredRedPackets.value.isEmpty else {
                return _cell
            }
            let redPacket = filteredRedPackets.value[indexPath.row]
            CreatedRedPacketViewModel.configure(cell: _cell, with: redPacket)
            
            cell = _cell
        }

        return cell
    }

}

extension WalletsViewModel {

    // For WalletCardTableViewCell
    static func configure(cell: WalletCardTableViewCell, with model: WalletModel) {
        let address = model.address
        cell.walletCardView.headerLabel.text = String(address.prefix(6))
        cell.walletCardView.captionLabel.text = address
        // cell.captionLabel.text = {
        //     guard let address = address else { return nil }
        //     let raw = address.removingPrefix("0x")
        //     return "0x" + raw.prefix(20) + "\n" + raw.suffix(20)
        // }()
        model.balanceInDecimal.asDriver()
            .map { decimal in
                guard let decimal = decimal,
                let decimalString = WalletService.balanceDecimalFormatter.string(from: decimal as NSNumber) else {
                    return "- ETH"
                }
            
                return decimalString + " ETH"
            }
            .drive(cell.walletCardView.balanceAmountLabel.rx.text)
            .disposed(by: cell.disposeBag)
    }
    
    // For WalletCardCollectionViewCell
    static func configure(cell: WalletCardCollectionViewCell, with model: WalletModel) {
        let address = model.address
        cell.walletCardView.headerLabel.text = String(address.prefix(6))
        cell.walletCardView.captionLabel.text = address
        // cell.captionLabel.text = {
        //     guard let address = address else { return nil }
        //     let raw = address.removingPrefix("0x")
        //     return "0x" + raw.prefix(20) + "\n" + raw.suffix(20)
        // }()
        model.balanceInDecimal.asDriver()
            .map { decimal in
                guard let decimal = decimal,
                    let decimalString = WalletService.balanceDecimalFormatter.string(from: decimal as NSNumber) else {
                        return "- ETH"
                }
                
                return decimalString + " ETH"
        }
        .drive(cell.walletCardView.balanceAmountLabel.rx.text)
        .disposed(by: cell.disposeBag)
    }

}

// MAKR: - UIPageViewControllerDataSource
extension WalletsViewModel: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard !walletModels.value.isEmpty else {
            return nil
        }
        
        guard let walletCardViewController = viewController as? WalletCardViewController else {
            return nil
        }
        
        let index = walletCardViewController.index
        guard index > 0 else {
            return nil
        }
        
        let viewController = WalletCardViewController()
        viewController.index = index - 1
        viewController.walletModel = walletModels.value[index - 1]
        
        return viewController
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard !walletModels.value.isEmpty else {
            return nil
        }
        
        guard let walletCardViewController = viewController as? WalletCardViewController else {
            return nil
        }
        
        let index = walletCardViewController.index
        guard index + 1 < walletModels.value.count else {
            return nil
        }
        
        let viewController = WalletCardViewController()
        viewController.index = index + 1
        viewController.walletModel = walletModels.value[index + 1]
        
        return viewController
    }
    
}

// MARK: - UICollectionViewDataSource
extension WalletsViewModel: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return walletModels.value.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: WalletCardCollectionViewCell.self), for: indexPath) as! WalletCardCollectionViewCell
        
        let walletModel = walletModels.value[indexPath.row]
        WalletsViewModel.configure(cell: cell, with: walletModel)
        
        return cell
    }
    
}
