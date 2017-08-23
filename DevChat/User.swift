//
//  User.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/3/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import Foundation

struct User {
    private var _name: String
    private var _profPicUrl: String
    private var _uid: String?
    
    var uid: String? {
        return _uid
    }
    
    var name: String {
        return _name
    }
    
    var profPicUrl: String {
        return _profPicUrl
    }
    
    
    init (uid: String, name: String, profPicUrl: String) {
        _uid = uid
        _name = name
        _profPicUrl = profPicUrl
    }
    
    init (snap: [String:Any]) {
        _name = snap["name"] as? String ?? ""
        _profPicUrl = snap["profPicUrl"] as? String ?? ""
    }
    
}
