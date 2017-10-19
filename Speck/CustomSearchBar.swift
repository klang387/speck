//
//  CustomSearchBar.swift
//  Speck
//
//  Created by Kevin Langelier on 9/11/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit

class CustomSearchBar: UISearchBar {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.borderWidth = 1
        layer.borderColor = self.barTintColor?.cgColor
        enablesReturnKeyAutomatically = false
        returnKeyType = .done
        
        for view : UIView in (self.subviews[0]).subviews {
            if let textField = view as? UITextField {
                textField.font = UIFont(name: "Avenir", size: 14)
            }
        }
    }

}
