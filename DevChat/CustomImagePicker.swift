//
//  CustomImagePicker.swift
//  Speck
//
//  Created by Kevin Langelier on 9/22/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit

class CustomImagePicker: UIImagePickerController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    override var shouldAutorotate: Bool {
        return true
    }

}
