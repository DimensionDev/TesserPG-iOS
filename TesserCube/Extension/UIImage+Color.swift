//
//  UIImage+Color.swift
//  TesserCube
//
//  Created by jk234ert on 2019/2/21.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

extension UIImage {
    
    static func placeholder(size: CGSize = CGSize(width: 1, height: 1), color: UIColor) -> UIImage {
        let render = UIGraphicsImageRenderer(size: size)
        
        return render.image { (context: UIGraphicsImageRendererContext) in
            context.cgContext.setFillColor(color.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    
}
