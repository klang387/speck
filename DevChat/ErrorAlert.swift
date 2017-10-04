//
//  ErrorAlert.swift
//  Speck
//
//  Created by Kevin Langelier on 9/25/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit

class ErrorAlert: UIAlertController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        addAction(action)
    }

}
