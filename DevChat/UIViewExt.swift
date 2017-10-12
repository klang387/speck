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
    
    func animateViewMoving(textField:UITextField?, constraint: NSLayoutConstraint?) {
        if textField != nil {
            constraint?.isActive = false
            guard let textFieldPosition = textField?.superview?.convert(textField!.frame, to: self).midY else {return}
            let targetY = frame.height > frame.width ? frame.height / 2.5 : frame.height / 4
            let targetPosition = -(textFieldPosition - targetY)
            if targetPosition < 0 {
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                    self.frame = CGRect(x: 0, y: targetPosition, width: self.frame.width, height: self.frame.height)
                })
            }
        } else {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                self.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
            }, completion: { finished in
                constraint?.isActive = true
            })
        }
    }
    
}
