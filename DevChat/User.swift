//
//  User.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/3/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import Foundation

struct User {
    private var _firstName: String
    private var _lastName: String
    private var _profPicUrl: String
    private var _uid: String
    private var _snapUrl: String?
    
    var uid: String {
        return _uid
    }
    
    var firstName: String {
        return _firstName
    }
    
    var lastName: String {
        return _lastName
    }
    
    var profPicUrl: String {
        return _profPicUrl
    }
    
    var snapUrl: String? {
        return _snapUrl
    }
    
    init (uid: String, firstName: String, lastName: String, profPicUrl: String) {
        _uid = uid
        _firstName = firstName
        _lastName = lastName
        _profPicUrl = profPicUrl
    }
    
    init (snap: [String:Any]) {      
        _uid = snap["sender"] as? String ?? ""
        _snapUrl = snap["databaseUrl"] as? String ?? ""
        
        if let profile = snap["senderProfile"] as? [String:String] {
            _firstName = profile["firstName"] ?? ""
            _lastName = profile["lastName"] ?? ""
            _profPicUrl = profile["profPicUrl"] ?? ""
        } else {
            _firstName = ""
            _lastName = ""
            _profPicUrl = ""
        }
    }
    
}
