//
//  CustomImagePicker.swift
//  Speck
//
//  Created by Kevin Langelier on 10/11/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit

class CustomImagePicker: UIImagePickerController {

    override var childForStatusBarHidden: UIViewController? {
        return nil
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        return .slide
    }
    
    override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }
    
    var statusBarHidden: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        statusBarHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        statusBarHidden = false
    }

}
