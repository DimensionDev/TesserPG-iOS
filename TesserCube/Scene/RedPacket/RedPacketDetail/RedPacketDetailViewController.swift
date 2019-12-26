//
//  RedPacketDetailViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-26.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift

final class RedPacketDetailViewModel: NSObject {
    
    let redPacket: RedPacket
    
    init(redPacket: RedPacket) {
        self.redPacket = redPacket
        super.init()
    }
    
}

extension RedPacketDetailViewModel {
    
    enum Section: Int, CaseIterable {
        case redPacket
        case message
        case claimer
    }
    
}

// MARK: - UITableViewDataSource
extension RedPacketDetailViewModel: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // Section
        // - 0: red packet cell
        // - 1: message cell
        // - 2: claimer list cell section
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section.allCases[section] {
        case .redPacket:
            return 1
        case .message:
            return 1
        case .claimer:
            // TODO:
            return 0
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
            
        case .claimer:
            fatalError()
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
    }
    
}

// MARK: - UITableViewDelegate
extension RedPacketDetailViewController: UITableViewDelegate {
    
    // Header
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch RedPacketDetailViewModel.Section.allCases[section] {
        case .message:
            return RedPacketMessageSectionHeaderView()
        default:
            return UIView()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch RedPacketDetailViewModel.Section.allCases[section] {
        case .message:
            return UITableView.automaticDimension
        default:
            return 10
        }
    }
    
    // Footer
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
    
}
