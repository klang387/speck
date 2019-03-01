//
//  AuthService.swift
//  Speck
//
//  Created by Kevin Langelier on 8/2/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseMessaging
import FacebookCore
import FacebookLogin

typealias Completion = (_ data: AnyObject?, _ error: ErrorAlert?) -> Void

class AuthService {
    private static let _instance = AuthService()
    
    static var instance: AuthService {
        return _instance
    }
    
    var currentUser: String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    var fcmToken: String {
        return Messaging.messaging().fcmToken!
    }
    
    func emailSignIn(email: String, password: String, completion: Completion?) {
        Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
            if error != nil {
                let errorAlert = ErrorAlert(title: "Uh Oh", message: error!.localizedDescription, preferredStyle: .alert)
                completion?(nil, errorAlert)
            } else {
                DataService.instance.addToken()
                completion?(user, nil)
            }
        })
    }
    
    func createUser(email: String, password: String, completion: Completion?) {
        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
            if error != nil {
                let errorAlert = ErrorAlert(title: "Uh Oh", message: error!.localizedDescription, preferredStyle: .alert)
                completion?(nil, errorAlert)
            } else {
                self.emailSignIn(email: email, password: password, completion: { (user, error) in
                    completion?(user, error)
                })
            }
        })
    }
    
    func facebookLogin(completion: @escaping (ErrorAlert?) -> Void) {
        let loginManager = LoginManager()
        var firstName = String()
        var lastName = String()
        var profPicUrl = String()
        loginManager.logIn(readPermissions: [.publicProfile, .email], viewController: nil) { (loginResult) in
            switch loginResult {
            case .failed:
                let alert = ErrorAlert(title: "Uh Oh", message: "Unable to login.  Please check your internet connection and try again!", preferredStyle: .alert)
                completion(alert)
            case .cancelled: break
            case .success(_, _, let accessToken):
                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
                Auth.auth().signInAndRetrieveData(with: credential, completion: { (result, error) in
                    if error != nil {
                        let alert = ErrorAlert(title: "Uh Oh", message: "Unable to login.  Please check your internet connection and try again!", preferredStyle: .alert)
                        completion(alert)
                    } else if let user = result?.user {
                        DataService.instance.addToken()
                        DataService.instance.profilesRef.child(user.uid).observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.hasChildren()  {
                                completion(nil)
                            } else {
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
                                                    if let email = user.email {
                                                        DataService.instance.saveUserToDatabase(uid: user.uid, firstName: firstName, lastName: lastName, profPicUrl: profPicUrl, email: email)
                                                        completion(nil)
                                                    }
                                                }
                                            }
                                        }
                                    case .failed:
                                        let alert = ErrorAlert(title: "Uh Oh", message: "Trouble logging in.  Please check your internet connection and try again!", preferredStyle: .alert)
                                        completion(alert)
                                    }
                                })
                            }
                        })
                    }
                })
            }
        }
    }
    
}
