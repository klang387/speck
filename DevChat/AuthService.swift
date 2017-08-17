//
//  AuthService.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/2/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import Foundation
import FirebaseAuth
import FacebookCore
import FacebookLogin

typealias Completion = (_ errMsg: String?, _ data: AnyObject?) -> Void

class AuthService {
    private static let _instance = AuthService()
    
    static var instance: AuthService {
        return _instance
    }
    
    func login(email: String, password: String, onComplete: Completion?) {
        Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
            if error != nil {
                self.handleFirebaseError(error: error! as NSError, onComplete: onComplete)
            } else {
                onComplete?(nil, user)
            }
        })
    }
    
    func createUser(email: String, password: String, onComplete: Completion?) {
        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
            if error != nil {
                self.handleFirebaseError(error: error! as NSError, onComplete: onComplete)
            } else {
                self.login(email: email, password: password, onComplete: onComplete)
            }
        })
    }
    
    func handleFirebaseError(error: NSError, onComplete: Completion?) {
        print(error.debugDescription)
        if let errorCode = AuthErrorCode(rawValue: error._code) {
            switch (errorCode) {
            case .invalidEmail:
                onComplete?("Invalid email address", nil)
                break
            case .wrongPassword:
                onComplete?("Invalid password", nil)
                break
            case .emailAlreadyInUse:
                onComplete?("Could not create account.  Email already in use.", nil)
                break
            case .userNotFound:
                onComplete?("User does not exist", nil)
                break
            default:
                onComplete?("There was a problem authenticating.  Try again.", nil)
            }
        }
    }
    
    func facebookLogin(completion: @escaping () -> Void) {
        let loginManager = LoginManager()
        var firstName = String()
        var lastName = String()
        var profPicUrl = String()
        loginManager.logIn([.publicProfile]) { (loginResult) in
            switch loginResult {
            case .failed(let error): print("Facebook login failed: \(error)")
            case .cancelled: print("User cancelled Facebook login.")
            case .success(let grantedPermissions, let declinedPermissions, let accessToken):
                print("Logged into Facebook with permissions: \(grantedPermissions)")
                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
                let request = GraphRequest(graphPath: "me", parameters: ["fields" : "first_name, last_name, picture.type(large)"])
                request.start({ (response, result) in
                    switch result{
                    case .success(let resultDict):
                        if let first = resultDict.dictionaryValue?["first_name"] as? String, let last = resultDict.dictionaryValue?["last_name"] as? String {
                            firstName = first
                            lastName = last
                        }
                        if let picture = resultDict.dictionaryValue?["picture"] as? [String:Any] {
                            if let data = picture["data"] as? [String:Any] {
                                if let picUrl = data["url"] as? String {
                                    profPicUrl = picUrl
                                }
                            }
                        }
                    case .failed(let error):
                        print("Facebook Graph Request Failed: \(error)")
                    }
                })
                Auth.auth().signIn(with: credential, completion: { (user, error) in
                    if (error != nil) {
                        print("Unable to sign in with Firebase: \(error)")
                    } else {
                        print("Successful sign in with Firebase")
                        DataService.instance.saveUserToDatabase(uid: user!.uid, firstName: firstName, lastName: lastName, profPicUrl: profPicUrl)
                        completion()
                    }
                })
            }
        }
    }
    
}





