//
//  BackNavBar.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/27/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit

class BackNavBar: UIView {

    var image: UIImage!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let imageView = UIImageView(image: image)
        
    }
    
    init (frame: CGRect, image: UIImage) {
        self.image = image
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
