//
//  WalletsViewModel.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-12.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class WalletsViewModel: NSObject {
    
    let disposeBag = DisposeBag()
    weak var walletViewController: UIViewController!

    // Input
    let walletModels = BehaviorRelay<[WalletModel]>(value: [])
    let redPackets = BehaviorRelay<[RedPacket]>(value: [])

    // Output
    let currentWalletModel = BehaviorRelay<WalletModel?>(value: nil)
    let currentWalletPageIndex = BehaviorRelay(value: 0)
    let filteredRedPackets = BehaviorRelay<[RedPacket]>(value: [])

    override init() {
        super.init()
        
        walletModels.asDriver()
            .drive(onNext: { [weak self] walletModels in
                self?.currentWalletModel.accept(walletModels.first)
                self?.currentWalletPageIndex.accept(0)
            })
            .disposed(by: disposeBag)
        
        Driver.combineLatest(currentWalletModel.asDriver(), redPackets.asDriver()) { currentWalletModel, redPackets -> [RedPacket] in
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
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return filteredRedPackets.value.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell

        switch indexPath.section {
        case 0:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: WalletPageTableViewCell.self), for: indexPath) as! WalletPageTableViewCell
            
            // Note: remove from parent in tableView:didEndDisplayingCell:forRowAtIndexPath:
            let child = _cell.pageViewController
            walletViewController.addChild(child)
            child.view.translatesAutoresizingMaskIntoConstraints = false
            _cell.contentView.addSubview(child.view)
            NSLayoutConstraint.activate([
                child.view.topAnchor.constraint(equalTo: _cell.contentView.topAnchor),
                child.view.leadingAnchor.constraint(equalTo: _cell.contentView.leadingAnchor),
                _cell.contentView.trailingAnchor.constraint(equalTo: child.view.trailingAnchor),
                _cell.pageControl.topAnchor.constraint(equalTo: child.view.bottomAnchor),
                child.view.heightAnchor.constraint(equalToConstant: 136),   // can not set dynamic height
            ])
            child.didMove(toParent: walletViewController)
            
            // bind page view controller data souce
            child.dataSource = self
            
            // setup page view controller initialViewController
            let initialViewController = WalletCardViewController()
            initialViewController.index = currentWalletPageIndex.value
            child.setViewControllers([initialViewController], direction: .forward, animated: false, completion: nil)
            if let walletModel = currentWalletModel.value {
                initialViewController.walletModel = walletModel
            }

            // setup page control
            walletModels.asDriver()
                .map { max($0.count, 1) }
                .drive(_cell.pageControl.rx.numberOfPages)
                .disposed(by: _cell.disposeBag)
            currentWalletPageIndex.asDriver()
                .drive(_cell.pageControl.rx.currentPage)
                .disposed(by: _cell.disposeBag)
            
            // Bind cell delegate
            _cell.delegate = self
            
            cell = _cell
            
        case 1:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RedPacketCardTableViewCell.self), for: indexPath) as! RedPacketCardTableViewCell
            
            let redPacket = filteredRedPackets.value[indexPath.row]
            CreatedRedPacketViewModel.configure(cell: _cell, with: redPacket)
            
            cell = _cell
            // let model = walletModels.value[indexPath.row]
            // WalletsViewModel.configure(cell: cell, with: model)
            
        default:
            fatalError()
        }

        return cell
    }

}

extension WalletsViewModel {

    static func configure(cell: WalletCardTableViewCell, with model: WalletModel) {
        let address = model.address
        cell.headerLabel.text = String(address.prefix(6))
        cell.captionLabel.text = address
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
            .drive(cell.balanceAmountLabel.rx.text)
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

// MARK: - WalletPageTableViewCellDelegate
extension WalletsViewModel: WalletPageTableViewCellDelegate {
    
    func walletPageTableViewCell(_ cell: WalletPageTableViewCell, didUpdateCurrentPage index: Int) {
        currentWalletPageIndex.accept(index)
        
        guard !walletModels.value.isEmpty else {
            currentWalletModel.accept(nil)
            return
        }
        
        currentWalletModel.accept(walletModels.value[index])
    }
    
}
