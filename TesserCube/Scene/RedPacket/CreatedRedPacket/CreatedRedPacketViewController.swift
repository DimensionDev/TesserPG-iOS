//
//  CreatedRedPacketViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-23.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

final class CreatedRedPacketViewModel: NSObject {
    
}

// MARK: - UITableViewDataSource
extension CreatedRedPacketViewModel: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RedPacketCardTableViewCell.self), for: indexPath) as! RedPacketCardTableViewCell
        return cell
    }
    
}

final class CreatedRedPacketViewController: UIViewController {
    
    let viewModel = CreatedRedPacketViewModel()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(RedPacketCardTableViewCell.self, forCellReuseIdentifier: String(describing: RedPacketCardTableViewCell.self))
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = ._systemGroupedBackground
        return tableView
    }()

    private lazy var bottomActionsView: UIStackView = {
        let stackView = UIStackView(frame: .zero)
        stackView.spacing = 12
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .fill
        return stackView
    }()
    
}

extension CreatedRedPacketViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Red Packet Created"
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(CreatedRedPacketViewController.doneBarButtonItemPressed(_:)))
        
        // Layout tableView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Layout bottom actions view
        bottomActionsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomActionsView)
        NSLayoutConstraint.activate([
            bottomActionsView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            bottomActionsView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: bottomActionsView.bottomAnchor, constant: 15),
        ])
        
        // Setup tableView
        tableView.dataSource = viewModel

        // Setup bottomActionsView
        #if !TARGET_IS_EXTENSION
        reloadActionsView()
        #endif
    }
    
}

#if !TARGET_IS_EXTENSION
extension CreatedRedPacketViewController {
    
    private func reloadActionsView() {
        bottomActionsView.arrangedSubviews.forEach { subview in
            bottomActionsView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        let hintLabel: UILabel = {
            let label = UILabel()
            label.numberOfLines = 0
            label.text = "Recipients may interpret the hint with Tesercube to open the Red Packet."
            label.font = FontFamily.SFProDisplay.regular.font(size: 20)
            label.lineBreakMode = .byWordWrapping
            label.textAlignment = .center
            return label
        }()
        let shareRedPacketButton: TCActionButton = {
            let button = TCActionButton()
            button.color = .systemBlue
            button.setTitle("Share Red Packet", for: .normal)
            button.setTitleColor(.white, for: .normal)
            return button
        }()
        
        bottomActionsView.addArrangedSubview(hintLabel)
        bottomActionsView.addArrangedSubview(shareRedPacketButton)
    }
}
#endif

extension CreatedRedPacketViewController {
    
    @objc private func doneBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}
