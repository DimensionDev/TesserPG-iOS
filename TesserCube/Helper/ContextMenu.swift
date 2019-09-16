//
//  ContextMenu.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-8-26.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

protocol ContextMenuActionTableViewDelegate: class {
    func tableView(_ tableView: UITableView, presentingViewController: UIViewController, actionsforRowAt indexPath: IndexPath) -> [ContextMenuAction]
}

protocol ContextMenuAction {
    var title: String { get }
    var discoverabilityTitle: String? { get }
    var image: UIImage? { get }

    @available(iOS 13.0, *)
    var identifier: UIAction.Identifier? { get }

    @available(iOS 13.0, *)
    var attributes: UIMenuElement.Attributes { get }

    @available(iOS 13.0, *)
    var state: UIMenuElement.State { get }

    var style: UIAlertAction.Style { get }

    var handler: () -> Void { get }

    @available(iOS 13.0, *)
    var menuElement: UIMenuElement? { get }

    var alertAction: UIAlertAction { get }
}
