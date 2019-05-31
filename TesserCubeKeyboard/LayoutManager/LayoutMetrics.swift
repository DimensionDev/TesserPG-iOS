//
//  LayoutMetrics.swift
//  TesserCubeKeyboard
//
//  Created by jk234ert on 2019/2/20.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

enum MetricName: String {
    case contactsBanner
    case topTitleBanner
    case recipientsBanner
    case cannotDecryptBanner
    case interpretResultBanner
}

let metrics: [MetricName: CGFloat] = [
    .contactsBanner: 206,
    .topTitleBanner: 42,
    .recipientsBanner: 42,
    .cannotDecryptBanner: 102,
    .interpretResultBanner: 206
]
