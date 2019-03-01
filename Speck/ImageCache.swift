//
//  ImageCache.swift
//  Speck
//
//  Created by Kevin Langelier on 9/20/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit

class ImageCache {
    
    private static let _instance = ImageCache()
    
    static var instance: ImageCache {
        return _instance
    }
    
    private var _profilePicCache: NSCache<NSString,UIImage> = NSCache()
    
    func getProfileImage(user: User, completion: @escaping (UIImage) -> Void) {
        if let image = _profilePicCache.object(forKey: user.uid as NSString) {
            completion(image)
        } else {
           URLSession.shared.dataTask(with: NSURL(string: user.profPicUrl)! as URL, completionHandler: { (data, response, error) -> Void in
                if error != nil {
                    return
                }
                DispatchQueue.main.async(execute: { () -> Void in
                    if let image = UIImage(data: data!) {
                        self._profilePicCache.setObject(image, forKey: user.uid as NSString)
                        completion(image)
                        
                    }
                })
            }).resume()
        }
        
    }
    
    func purgeCache() {
        _profilePicCache.removeAllObjects()
    }
}
