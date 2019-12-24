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
    weak var walletViewController: WalletsViewController!
    
    lazy var walletPageTableViewCell: WalletPageTableViewCell = {
        let cell = WalletPageTableViewCell()
        
        let child = cell.pageViewController
        walletViewController.addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(child.view)
        NSLayoutConstraint.activate([
            child.view.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            child.view.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            cell.contentView.trailingAnchor.constraint(equalTo: child.view.trailingAnchor),
            cell.pageControl.topAnchor.constraint(equalTo: child.view.bottomAnchor),
            child.view.heightAnchor.constraint(equalToConstant: 136),   // can not set dynamic height
        ])
        child.didMove(toParent: walletViewController)
        
        // bind page view controller data souce
        child.dataSource = self
        
        return cell
    }()

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

    init(walletsViewController: WalletsViewController) {
        self.walletViewController = walletsViewController
        super.init()
        
        walletModels.asDriver()
            .drive(onNext: { [weak self] walletModels in
                guard let `self` = self else { return }
                self.currentWalletModel.accept(walletModels.first)
                self.currentWalletPageIndex.accept(0)
                
                // setup page view controller initialViewController
                let initialViewController = WalletCardViewController()
                initialViewController.index = self.currentWalletPageIndex.value
                self.walletPageTableViewCell.pageViewController.setViewControllers([initialViewController], direction: .forward, animated: true, completion: nil)
                if let walletModel = self.currentWalletModel.value {
                    initialViewController.walletModel = walletModel
                }
            
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
        let cell: UITableViewCell

        switch Section.allCases[indexPath.section] {
        case .wallet:
            let _cell = walletPageTableViewCell
        
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
            
        case .redPacket:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RedPacketCardTableViewCell.self), for: indexPath) as! RedPacketCardTableViewCell
            
            guard indexPath.row < filteredRedPackets.value.count, !filteredRedPackets.value.isEmpty else {
                return _cell
            }
            
            cell = _cell
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
