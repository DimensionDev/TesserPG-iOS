//
//  MeViewModel.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/18.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import SwifterSwift
import RxSwift
import RxCocoa
import ConsolePrint

class MeViewModel: NSObject {
    let disposeBag = DisposeBag()

    let hasKey: Driver<Bool>
    let keys = BehaviorRelay<[TCKey]>(value: [])
    
    let cellDidClick = PublishRelay<KeyCardCell>()
    
    override init() {
        hasKey = keys.asDriver().map { !$0.isEmpty }

        ProfileService.default.keys.asDriver()
            .map { $0.filter { $0.hasSecretKey } }
            .drive(keys)
            .disposed(by: disposeBag)
    }
}

extension MeViewModel {

    func deleteKey(_ key: TCKey, completion: @escaping (Error?) -> Void) {
        // TODO: group contact's keys as one section in tableView
        for pair in ProfileService.default.contactKeyPairs.value where pair.1.contains(where: { $0.longIdentifier == key.longIdentifier}) {
            do {
                try pair.0.removeKey(key)
            } catch {
                consolePrint(error)
                return
            }
        }
    }

}

extension MeViewModel: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return keys.value.isEmpty ? 1 : keys.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: KeyCardCell.self, for: indexPath)
        if keys.value.isEmpty {
            cell.keyValue = .mockKey
        } else {
            guard indexPath.row < keys.value.count else {
                assertionFailure()
                return cell
            }
            let key = keys.value[indexPath.row]
            cell.keyValue = .TCKey(value: key)
        }
        return cell
    }

}
