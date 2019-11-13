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

    let walletModels = BehaviorRelay<[WalletModel]>(value: [])

    override init() {
        super.init()
    }

}

// MARK: - UITableViewDataSource
extension WalletsViewModel: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return walletModels.value.isEmpty ? 1 : 0
        case 1:
            return walletModels.value.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: WalletCardTableViewCell.self), for: indexPath) as! WalletCardTableViewCell

        switch indexPath.section {
        case 1:
            let model = walletModels.value[indexPath.row]
            WalletsViewModel.configure(cell: cell, with: model)
        default:
            break
        }

        return cell
    }

}

extension WalletsViewModel {

    static func configure(cell: WalletCardTableViewCell, with model: WalletModel) {
        let address = model.address
        cell.headerLabel.text = "0x" + address.suffix(4)
        cell.captionLabel.text = address
//            cell.captionLabel.text = {
//                guard let address = address else { return nil }
//                let raw = address.removingPrefix("0x")
//                return "0x" + raw.prefix(20) + "\n" + raw.suffix(20)
//            }()
        model.balanceInDecimal.asDriver()
            .map { $0.string }
            .drive(cell.balanceAmountLabel.rx.text)
            .disposed(by: cell.disposeBag)
    }

}
