//
//  ContactListViewModel.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/27.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ContactListViewModel: NSObject {

    typealias ContactID = Int64

    let hasContact: Driver<Bool>
    let contacts = BehaviorRelay<[Contact]>(value: [])

    var selectedContactIDs = Set<ContactID>()
    
//    let cellDidClick = PublishRelay<KeyCardCell>()
    
    override init() {
        hasContact =  contacts.asDriver().map { !$0.isEmpty }
    }
}
