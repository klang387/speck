//
//  SlideInPresentationController.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/27/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit

class SlideInPresentationController: UIPresentationController {

    private var direction: PresentationDirection
    
    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, direction: PresentationDirection) {
        self.direction = direction
        
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }
    
    
    
}
