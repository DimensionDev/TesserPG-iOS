//
//  OpenRedPacketViewController.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-12-24.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import BigInt
import RxSwift
import RxCocoa
import UITextView_Placeholder

final class OpenRedPacketViewModel {

    // Input
    let message = BehaviorRelay<String>(value: "")
    
}

extension OpenRedPacketViewModel {
    
    func openRedPacket() -> Single<RedPacket> {
        do {
            let result = try RedPacketService.decryptResult(forArmoredEncPayload: message.value)
            let rawPayload = result.rawPayload
            
            let redPacket = RedPacket()
            redPacket.contract_version = Int(rawPayload.contract_version)
            redPacket.contract_address = rawPayload.contract_address
            redPacket.uuids.append(objectsIn: rawPayload.passwords)
            redPacket.is_random = rawPayload.is_random
            redPacket.block_creation_time.value = Int(rawPayload.creation_time)
            redPacket.duration = Int(rawPayload.duration)
            redPacket.red_packet_id = rawPayload.rpid
            redPacket.raw_payload = result.rawPayloadJSON
            redPacket.enc_payload = result.encPayload
            redPacket.sender_address = rawPayload.sender.address
            redPacket.sender_name = rawPayload.sender.name
            guard let sendTotal = BigUInt(rawPayload.total, radix: 10) else {
                return Single.error(RedPacketService.Error.openRedPacketFail("cannot read send amount"))
            }
            redPacket.send_total = sendTotal
            redPacket.send_message = rawPayload.sender.message
            redPacket.status = .incoming
            redPacket.network = rawPayload.network ?? .mainnet
            redPacket.token_type = rawPayload.token_type
            redPacket.received_time = Date()
            
            // Check token type if .erc20
            if rawPayload.token_type == .erc20 {
                guard let token = rawPayload.token else {
                    return Single.error(RedPacketService.Error.openRedPacketFail("cannot read token"))
                }
                do {
                    let realm = try RedPacketService.realm()
                    
                    var _erc20Token: ERC20Token
                    if let erc20Token = realm.object(ofType: ERC20Token.self, forPrimaryKey: token.address) {
                        _erc20Token = erc20Token

                    } else {
                        // not store in database, insert new token
                        let erc20Token = ERC20Token()
                        erc20Token.id = token.address
                        erc20Token.address = token.address
                        erc20Token.name = token.name
                        erc20Token.symbol = token.symbol
                        erc20Token.decimals = token.decimals
                        erc20Token.network = rawPayload.network ?? .mainnet
                        erc20Token.is_user_defind = true
                        
                        try realm.write {
                            realm.add(erc20Token)
                        }
                        _erc20Token = erc20Token
                    }
                    // set redPacket.erc20_token relationship
                    redPacket.erc20_token = _erc20Token
                    
                } catch {
                    return Single.error(RedPacketService.Error.openRedPacketFail(error.localizedDescription))
                }
                
            }
            
            return Single.just(redPacket)
            
        } catch {
            return Single.error(error)
        }
    }
    
}

final class OpenRedPacketViewController: TCBaseViewController {
    
    let disposeBag = DisposeBag()
    let viewModel = OpenRedPacketViewModel()

    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        if #available(iOS 13, *) {
            scrollView.backgroundColor = .systemBackground
        } else {
            scrollView.backgroundColor = ._systemBackground
        }
        return scrollView
    }()
    
    let messageTextView: UITextView = {
        let textView = UITextView()
        textView.placeholderColor = ._secondaryLabel
        textView.placeholder = L10n.ComposeMessageViewController.TextView.Message.placeholder
        textView.isScrollEnabled = false
        textView.font = FontFamily.SFProText.regular.font(size: 15)
        textView.textContainerInset.left = RecipientContactPickerView.leadingMargin - 4
        textView.backgroundColor = .clear
        return textView
    }()
    
    override func configUI() {
        super.configUI()
        
        title = "Open Red Packet"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: L10n.Common.Button.cancel, style: .plain, target: self, action: #selector(OpenRedPacketViewController.cancelBarButtonItemPressed(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: L10n.ComposeMessageViewController.BarButtonItem.finish, style: .done, target: self, action: #selector(OpenRedPacketViewController.doneBarButtonItemPressed(_:)))
        
        let margin = UIApplication.shared.keyWindow.flatMap { $0.safeAreaInsets.top + $0.safeAreaInsets.bottom } ?? 0
        let barHeight = navigationController?.navigationBar.bounds.height ?? 0
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0),
            scrollView.contentLayoutGuide.heightAnchor.constraint(greaterThanOrEqualToConstant: view.bounds.height - margin - barHeight),
        ])
        
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(messageTextView)
        NSLayoutConstraint.activate([
            messageTextView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            messageTextView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            messageTextView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            messageTextView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
        ])
        
        messageTextView.rx.text.orEmpty.asDriver()
            .drive(viewModel.message)
            .disposed(by: disposeBag)
    }
    
}

extension OpenRedPacketViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if hasValidArmor(), messageTextView.text.isEmpty {
            messageTextView.text = UIPasteboard.general.string
        }
    }
    
}

extension OpenRedPacketViewController {
    
    @objc private func cancelBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func doneBarButtonItemPressed(_ sender: UIBarButtonItem) {
        viewModel.openRedPacket()
            .subscribeOn(ConcurrentDispatchQueueScheduler.init(qos: .userInitiated))
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] redPacket in
                guard let `self` = self else { return }
                
                do {
                    // FIXME: duplicated red packet insert issue
                    let realm = try RedPacketService.realm()
                    guard realm.objects(RedPacket.self).filter("red_packet_id == %@", redPacket.red_packet_id ?? "").isEmpty else {
                        throw RedPacketService.Error.openRedPacketFail("This red packet has been opened by Tessercube")
                    }
                    try realm.write {
                        realm.add(redPacket)
                    }
                    let viewModel = ClaimRedPacketViewModel(redPacket: redPacket)
                    Coordinator.main.present(scene: .claimRedPacket(viewModel: viewModel), from: self, transition: .detail, completion: nil)
                    
                } catch {
                    let message = error.localizedDescription
                    self.showSimpleAlert(title: L10n.Common.Alert.error, message: message)
                }
            
            }, onError: { [weak self] error in
                    guard let `self` = self else { return }
                    let message = error.localizedDescription
                    self.showSimpleAlert(title: L10n.Common.Alert.error, message: message)
            })
            .disposed(by: disposeBag)
    }
    
}

extension OpenRedPacketViewController {
    
    private func hasValidArmor() -> Bool {
        if UIPasteboard.general.hasStrings,
        let pasteString = UIPasteboard.general.string,
        pasteString.contains("---Begin Smart Text---") {
            return true
        }
        
        return false
    }
    
}
