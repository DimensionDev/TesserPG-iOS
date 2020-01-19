//
//  RedPacketDetailViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-26.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import os
import UIKit
import RxSwift
import RxCocoa
import RxSwiftUtilities
import DeepDiff
import Web3
import DMS_HDWallet_Cocoa

final class RedPacketDetailViewModel: NSObject {
        
    let disposeBag = DisposeBag()
//    let checkClaimedListActivityIndicator = ActivityIndicator()
    
    // Input
    let redPacket: RedPacket
    
    // Output
//    let isFetchingClaimedList: Driver<Bool>

//    let claimedRecord = BehaviorRelay<[RedPacketService.RedPacketClaimedRecord]>(value: [])
//    let claimedRecordDiff: Observable<([RedPacketService.RedPacketClaimedRecord], [RedPacketService.RedPacketClaimedRecord])>
    
    // For DeepDiff safe update data source
//    var _claimedRecord: [RedPacketService.RedPacketClaimedRecord] = []
    
    init(redPacket: RedPacket) {
        self.redPacket = redPacket
//        isFetchingClaimedList = checkClaimedListActivityIndicator.asDriver()
//        claimedRecordDiff = BehaviorRelay.zip(claimedRecord, claimedRecord.skip(1)) { ($0, $1) }
        
        super.init()
        
        // Use contract claimer to indicate fetching status
//        if let contractEthereumAddress = try? EthereumAddress(hex: redPacket.contract_address, eip55: false) {
//            let record = RedPacketService.RedPacketClaimedRecord(claimed: 0, claimer: contractEthereumAddress)
//            claimedRecord.accept([record])
//            _claimedRecord = [record]
//        }
        
//        RedPacketService.checkClaimedList(for: redPacket)
//            .trackActivity(checkClaimedListActivityIndicator)
//            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
//            .retry(3)
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { [weak self] records in
//                guard let `self` = self else { return }
//                self.claimedRecord.accept(records)
//
//            }, onError: { error in
//                os_log("%{public}s[%{public}ld], %{public}s: fetch claimed list error: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//                self.claimedRecord.accept([])
//            })
//            .disposed(by: disposeBag)
    }
    
}

extension RedPacketDetailViewModel {
    
    enum Section: Int, CaseIterable {
        case redPacket
        case message
        // case claimer
    }
    
}

// MARK: - UITableViewDataSource
extension RedPacketDetailViewModel: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // Section
        // - 0: red packet cell
        // - 1: message cell
        // - 2: claimer list cell section (not use)
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section.allCases[section] {
        case .redPacket:
            return 1
        case .message:
            return 1
        // case .claimer:
        //     return _claimedRecord.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        switch Section.allCases[indexPath.section] {
        case .redPacket:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RedPacketCardTableViewCell.self), for: indexPath) as! RedPacketCardTableViewCell
            CreatedRedPacketViewModel.configure(cell: _cell, with: redPacket)
            cell = _cell
            
        case .message:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RedPacketMessageTableViewCell.self), for: indexPath) as! RedPacketMessageTableViewCell
            
            if redPacket.send_message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                _cell.messageLabel.text = "No message"
                _cell.messageLabel.textColor = ._secondaryLabel
            } else {
                _cell.messageLabel.text = redPacket.send_message
            }
            
            // Setup separator line
            UITableView.setupTopSectionSeparatorLine(for: _cell)
            UITableView.setupBottomSectionSeparatorLine(for: _cell)
            
            cell = _cell
            
//        case .claimer:
//            let record = _claimedRecord[indexPath.row]
//            let contractEthereumAddress = try? EthereumAddress(hex: redPacket.contract_address, eip55: false)
//            let isStubRecord: Bool = {
//                guard let contractEthereumAddress = contractEthereumAddress else {
//                    return false
//                }
//
//                return record.claimer == contractEthereumAddress
//            }()
//
//            let helper = RedPacketHelper(for: redPacket)
//
//            if isStubRecord {
//                let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RedPacketClaimerFetchActivityIndicatorTableViewCell.self), for: indexPath) as! RedPacketClaimerFetchActivityIndicatorTableViewCell
//                cell = _cell
//            } else {
//                let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RedPacketClaimerTableViewCell.self), for: indexPath) as! RedPacketClaimerTableViewCell
//
//                let address = record.claimer.hex(eip55: false)
//                _cell.nameLabel.text = String(address.prefix(6))
//                _cell.addressLabel.text = address
//                _cell.amountLabel.text = {
//                    let claimedAmountInDecimal = (Decimal(string: String(record.claimed)) ?? Decimal(0)) / helper.exponent
//                    let formatter = helper.formatter
//                    let ethDecimalString = formatter.string(from: claimedAmountInDecimal as NSNumber)
//                    return ethDecimalString.flatMap { $0 + " \(helper.symbol)" } ?? "- \(helper.symbol)"
//                }()
//
//                cell = _cell
//            }
//
//            UITableView.removeSeparatorLine(for: cell)
//
//            let isFirst = indexPath.row == 0
//            if isFirst {
//                UITableView.setupTopSectionSeparatorLine(for: cell)
//            }
//
//            let isLast = indexPath.row == _claimedRecord.count - 1
//            if isLast {
//                UITableView.setupBottomSectionSeparatorLine(for: cell)
//            } else {
//                UITableView.setupBottomCellSeparatorLine(for: cell)
//            }
            
        }
        
        return cell
    }
    
}

final class RedPacketDetailViewController: TCBaseViewController {
    
    let disposeBag = DisposeBag()
    
    var viewModel: RedPacketDetailViewModel!
    
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(RedPacketCardTableViewCell.self, forCellReuseIdentifier: String(describing: RedPacketCardTableViewCell.self))
        tableView.register(RedPacketMessageTableViewCell.self, forCellReuseIdentifier: String(describing: RedPacketMessageTableViewCell.self))
        tableView.register(RedPacketClaimerTableViewCell.self, forCellReuseIdentifier: String(describing: RedPacketClaimerTableViewCell.self))
        tableView.register(RedPacketClaimerFetchActivityIndicatorTableViewCell.self, forCellReuseIdentifier: String(describing: RedPacketClaimerFetchActivityIndicatorTableViewCell.self))
        tableView.separatorStyle = .none
        return tableView
    }()
    
    override func configUI() {
        super.configUI()

        title = "Red Packet Detail"
        navigationItem.largeTitleDisplayMode = .never
        
        // Layout tableView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
        ])
        
        // Setup tableView data source
        tableView.delegate = self
        tableView.dataSource = viewModel
        
//        viewModel.claimedRecordDiff.asObservable()
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { [weak self] old, new in
//                guard let `self` = self else { return }
//                let changes = diff(old: old, new: new)
//                let insertionAnimation: UITableView.RowAnimation = old.count == 1 ? .fade : .automatic
//                let deletionAnimation: UITableView.RowAnimation = old.count == 1 ? .fade : .automatic
//                let replacementAnimation: UITableView.RowAnimation = old.count == 1 ? .fade : .automatic
//                self.tableView.reload(
//                    changes: changes,
//                    section: RedPacketDetailViewModel.Section.claimer.rawValue,
//                    insertionAnimation: insertionAnimation,
//                    deletionAnimation: deletionAnimation,
//                    replacementAnimation: replacementAnimation,
//                    updateData: {
//                        self.viewModel._claimedRecord = new
//                    }, completion: nil)
//            })
//            .disposed(by: disposeBag)
    }
    
}

// MARK: - UITableViewDelegate
extension RedPacketDetailViewController: UITableViewDelegate {
    
    // Header
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch RedPacketDetailViewModel.Section.allCases[section] {
        case .message:
            let header = RedPacketDetailTableSectionHeaderView()
            header.headerLabel.text = "Message"
            return header
        
//        case .claimer:
//            guard !viewModel._claimedRecord.isEmpty else {
//                return UIView()
//            }
//            let header = RedPacketDetailTableSectionHeaderView()
//            header.headerLabel.text = "Opened by"
//            return header
            
        default:
            return UIView()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch RedPacketDetailViewModel.Section.allCases[section] {
        case .message:
            return UITableView.automaticDimension
//        case .claimer:
//            guard !viewModel._claimedRecord.isEmpty else {
//                return 10
//            }
//            return UITableView.automaticDimension
        default:
            return 10
        }
    }
    
    // Cell
    
    // Footer
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
    
}
