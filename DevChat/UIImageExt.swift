//
//  UIImageExt.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/26/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit

extension UIImage{
    convenience init(view: UIView) {
        
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: (image?.cgImage)!)
        
    }
}
