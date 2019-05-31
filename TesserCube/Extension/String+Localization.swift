//
//  String+Localization.swift
//  TesserCube
//
//  Created by jk234ert on 2019/3/27.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation

extension String {
    
    var isIncludeChinese: Bool {
        for ch in self.unicodeScalars {
            // 中文字符范围：0x4e00 ~ 0x9fff
            if (0x4e00 < ch.value  && ch.value < 0x9fff) {
                return true
            }
        }
        return false
    }
    
    var pinyin: String {
        if isIncludeChinese {
            let stringRef = NSMutableString(string: self) as CFMutableString
            // 转换为带音标的拼音
            CFStringTransform(stringRef, nil, kCFStringTransformToLatin, false);
            // 去掉音标
            CFStringTransform(stringRef, nil, kCFStringTransformStripCombiningMarks, false);
            let pinyin = stringRef as String
            return pinyin
        } else {
            return self
        }
    }
}
