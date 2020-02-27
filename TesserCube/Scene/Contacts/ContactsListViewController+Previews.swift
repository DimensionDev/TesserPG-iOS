//
//  ContactsListViewController+Previews.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-10-8.
//  Copyright © 2019 Sujitech. All rights reserved.
//

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ContactsListViewControllerRepresentable: UIViewControllerRepresentable {

    let contacts: [Contact]
    let isPickContactMode: Bool

    typealias UIViewControllerType = ContactsListViewController

    func makeUIViewController(context: Context) -> ContactsListViewController {
        return ContactsListViewController()
    }

    func updateUIViewController(_ contactsListViewController: ContactsListViewController, context: Context) {
        contactsListViewController.viewModel.contacts.accept(contacts)
        contactsListViewController.isPickContactMode = isPickContactMode
    }

}

@available(iOS 13.0, *)
struct ContactsListViewController_Previews: PreviewProvider {

    static let English = [
        "Daniel Parry",
        "Rory Grant",
        "Alexander Stone",
        "Kieran Allen",
        "Oscar Taylor",
        "Jett Lopez",
        "Donald Evans",
        "Jonathon Daniels",
        "Bo Lewis",
        "Rowan Macias",
    ].map { Contact(id: nil, name: $0) }

    static let Chinese = [
        "李永华", "张隆磊", "方秀伟", "孙贵民", "王慧文", "张海梁", "孔晓潼", "于其成", "王贵月", "张能曼", "洪吟夫", "李姣鹏", "梁蒋泽", "申以炳", "洪云群", "张志磊", "于志博", "吴苗生", "孙立国", "范秋娟", "王国浩", "李来雨", "刘雨进", "万飞勋", "杨思性", "徐玉武", "吕玉辉", "俞雪江", "杨隽珊", "林方斌", "梁海萌", "张宇荣", "董成阳", "田芳娟", "卢盛才", "梁文如", "王安锦", "樊瑛霞", "万海业", "林周明", "王磊捷", "张学峰", "蒋传勇", "傅冲含", "侯晓品", "杜国广", "周凤琼", "马志生", "李孜天", "王盛艳", "陈建燕", "常梅江", "陈栗璐", "陈芮睿", "王加南", "刘东利", "杨建华", "高力兴", "刘翁彬", "马树婷", "康云桥"
    ].map { Contact(id: nil, name: $0) }

    static let Japanese = [
        "柴刈康纯", "雨田寿江", "曽根原晴奈", "赤藤千絵子", "尾前沙理奈", "木名瀬铃子", "下程美沙", "杉野目裕之", "泉王子凛", "", "川野英子", "角野麻理子", "垣内美佐子", "沢部亜理纱", "稲荷絵里子", "野州千佳"
    ].map { Contact(id: nil, name: $0) }

    static let contacts: [[Contact]] = [
        English, Chinese, Japanese,
    ]

    static var previews: some View {
        Group {
            ForEach(0..<contacts.count) { item in
                NavigationView {
                    ContactsListViewControllerRepresentable(contacts: contacts[item], isPickContactMode: false)
                        .navigationBarTitle(Text("Contacts"))
                }
                .previewDisplayName("Normal")

                NavigationView {
                    ContactsListViewControllerRepresentable(contacts: contacts[item], isPickContactMode: true)
                        .navigationBarTitle(Text("Contacts"))
                }
                .previewDisplayName("Pick Mode")
            }
        }
    }

}

#endif
