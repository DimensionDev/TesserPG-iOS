//
//  EditingRedPacketViewController.swift
//  TesserCube
//
//  Created by jk234ert on 11/6/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

class EditingRedPacketViewController: UIViewController {
    
    @IBOutlet weak var amountTitleLabel: UILabel!
    @IBOutlet weak var splitMethodTitleLabel: UILabel!
    @IBOutlet weak var sharesTitleLabel: UILabel!
    @IBOutlet weak var walletTitleLabel: UILabel!
    @IBOutlet weak var currentBalanceTitleLabel: UILabel!
    
    @IBOutlet weak var sharesValueLabel: UILabel!
    @IBOutlet weak var sharesStepper: UIStepper!

    @IBOutlet weak var splitMethodTableView: UITableView!
    @IBOutlet weak var walletTableView: UITableView!
    
    var wallets: [TestWallet] = []
    
    var splitMethodProvider: RedPacketSplitMethodProvider?
    var walletProvider: RedPacketWalletProvider?
    
    var redPacketProperty = RedPacketProperty()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        wallets = testWallets
        splitMethodProvider = RedPacketSplitMethodProvider(redPacketProperty: redPacketProperty, tableView: splitMethodTableView)
        walletProvider = RedPacketWalletProvider(tableView: walletTableView)
        configNavBar()
        configUI()
    }
    
    private func configNavBar() {
        title = "Creating Red Packet"
        navigationController?.navigationBar.barTintColor = UIColor._tertiarySystemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(nextBarButtonItemClicked))
    }
    
    private func configUI() {
        sharesValueLabel.text = "\(redPacketProperty.sharesCount)"
    }

    @IBAction func stepperDidClicked(_ sender: UIStepper) {
        redPacketProperty.sharesCount = Int(sender.value)
        configUI()
    }
    
    @objc
    private func nextBarButtonItemClicked() {
        
    }
}

// Mock Testing Data

struct TestWallet {
    let address: String
    let amount: Int
}
extension EditingRedPacketViewController {
    var testWallets: [TestWallet] {
        return [
            TestWallet(address: "0x1191", amount: 25),
            TestWallet(address: "0x3389", amount: 35)
        ]
    }
}
