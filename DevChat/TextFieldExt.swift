//
//  TextFieldExt.swift
//  Devslopes Social
//
//  Created by Kevin Langelier on 7/13/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit

extension UITextField {
    
    func animateViewMoving(up:Bool, moveValue:CGFloat, view: UIView) {
        let movementDuration: TimeInterval = 0.2
        let movement: CGFloat = (up ? -moveValue : moveValue)
        UIView.beginAnimations("animateView", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(movementDuration)
        view.frame = view.frame.offsetBy(dx: 0, dy: movement)
        UIView.commitAnimations()
    }
    
}
