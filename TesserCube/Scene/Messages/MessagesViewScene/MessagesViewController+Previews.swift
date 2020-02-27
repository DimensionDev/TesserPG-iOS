//
//  MessagesViewController+Previews.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-10-8.
//  Copyright © 2019 Sujitech. All rights reserved.
//

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct MessagesViewControllerRepresentable: UIViewControllerRepresentable {

    let stub: PreviewStub
    let selectDraftSegment: Bool
    let isEditing: Bool

    typealias UIViewControllerType = MessagesViewController

    func makeUIViewController(context: Context) -> MessagesViewController {
        return MessagesViewController()
    }

    func updateUIViewController(_ messagesViewController: MessagesViewController, context: Context) {
        do {
            try stub.inject()
        } catch {
            // will fail when second time exec
        }

        // update segement control
        messagesViewController.segmentedControl.selectedSegmentIndex = selectDraftSegment ? 1 : 0
        messagesViewController.viewModel.selectedSegmentIndex.accept(selectDraftSegment ? 1 : 0)

        // update editing mode
        messagesViewController.tableView.isEditing = isEditing

        // force data source update
        if #available(iOS 13.0, *) {
            guard let dataSource = messagesViewController.viewModel.diffableDataSource as? UITableViewDiffableDataSource<MessagesViewModel.Section, Message> else {
                assertionFailure()
                return
            }

            var snapsot = NSDiffableDataSourceSnapshot<MessagesViewModel.Section, Message>()
            snapsot.appendSections([.main])
            snapsot.appendItems(messagesViewController.viewModel.messages.value)
            dataSource.apply(snapsot)
        }
    }
}

@available(iOS 13.0, *)
struct MessagesViewController_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            NavigationView {
                MessagesViewControllerRepresentable(stub: PreviewStub.default, selectDraftSegment: false, isEditing: false)
                    .navigationBarTitle("Messages")
            }
            .previewDisplayName("Normal")

            NavigationView {
                MessagesViewControllerRepresentable(stub: PreviewStub.default, selectDraftSegment: false, isEditing: true)
                    .navigationBarTitle("Messages")
            }
            .previewDisplayName("Normal - Editing")

            NavigationView {
                MessagesViewControllerRepresentable(stub: PreviewStub.default, selectDraftSegment: true, isEditing: false)
                    .navigationBarTitle("Messages")
            }
            .previewDisplayName("Draft")
        }
    }

}

#endif
