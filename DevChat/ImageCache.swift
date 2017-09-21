//
//  ImageCache.swift
//  DevChat
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
    
    var profilePicCache: NSCache<NSString,UIImage> = NSCache()
}
