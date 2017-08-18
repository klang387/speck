//
//  UIImageViewExt.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/18/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import AVKit

extension UIImageView {
    public func imageFromServerURL(urlString: String) {
        
        URLSession.shared.dataTask(with: NSURL(string: urlString)! as URL, completionHandler: { (data, response, error) -> Void in
            
            if error != nil {
                print(error)
                return
            }
            DispatchQueue.main.async(execute: { () -> Void in
                let image = UIImage(data: data!)
                self.image = image
            })
            
        }).resume()
    }
}
