//
//  UIViewExt.swift
//  Speck
//
//  Created by Kevin Langelier on 9/6/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit

extension UIView {
    
    func UIColorFromHex(rgbValue:UInt32, alpha:Double=1.0)->UIColor {
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        
        return UIColor(red:red, green:green, blue:blue, alpha:CGFloat(alpha))
    }
    
    func animateViewMoving(textField:UITextField?, view: UIView) {
        if textField != nil {
            guard let textFieldPosition = textField?.superview?.convert(textField!.frame, to: view).midY else {return}
            let targetY = view.frame.height > view.frame.width ? view.frame.height / 2.5 : view.frame.height / 4
            let targetPosition = -(textFieldPosition - targetY)
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                view.frame = CGRect(x: 0, y: targetPosition, width: view.frame.width, height: view.frame.height)
            })
        } else {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                view.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
            })
        }
    }
    
}
