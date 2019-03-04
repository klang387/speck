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
    
    var eulaApproved = false
    
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
        var email = String()
        var profPicUrl = String()
        loginManager.logIn(readPermissions: [.publicProfile, .email], viewController: nil) { (loginResult) in
            let presentAlert: (()->Void) = {
                let alert = ErrorAlert(title: "Uh Oh", message: "Unable to login.  Please check your internet connection and try again!", preferredStyle: .alert)
                completion(alert)
            }
            switch loginResult {
            case .failed:
                presentAlert()
            case .cancelled: break
            case .success(_, _, let accessToken):
                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
                Auth.auth().signInAndRetrieveData(with: credential, completion: { (result, error) in
                    if error != nil {
                        presentAlert()
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
                                        firstName = resultDict.dictionaryValue?["first_name"] as? String ?? ""
                                        lastName = resultDict.dictionaryValue?["last_name"] as? String ?? ""
                                        email = user.email ?? ""
                                        if let picture = resultDict.dictionaryValue?["picture"] as? [String:Any],
                                            let data = picture["data"] as? [String:Any],
                                            let picUrl = data["url"] as? String {
                                            
                                            URLSession.shared.dataTask(with: URL(string: picUrl)!, completionHandler: { (data, response, error) -> Void in
                                                if error != nil || data == nil {
                                                    presentAlert()
                                                } else {
                                                    DispatchQueue.main.async {
                                                        if let imageData = UIImage(data: data!)?.jpegData(compressionQuality: 0.2) {
                                                            let imageName = NSUUID().uuidString
                                                            DataService.instance.usersRef.child(user.uid).child("profPicStorageRef").observeSingleEvent(of: .value, with: { (snapshot) in
                                                                DataService.instance.usersRef.child(user.uid).child("profPicStorageRef").setValue(imageName)
                                                                if let profPicStorageRef = snapshot.value as? String {
                                                                    DataService.instance.profPicStorageRef.child(profPicStorageRef).delete()
                                                                }
                                                            })
                                                            let ref = DataService.instance.profPicStorageRef.child(imageName)
                                                            ref.putData(imageData, metadata: nil, completion: { (metadata, putError) in
                                                                guard putError == nil else { presentAlert(); return }
                                                                ref.downloadURL(completion: { (url, urlError) in
                                                                    guard urlError == nil else { presentAlert(); return }
                                                                    profPicUrl = url?.absoluteString ?? ""
                                                                    DataService.instance.saveUserToDatabase(uid: user.uid, firstName: firstName, lastName: lastName, profPicUrl: profPicUrl, email: email)
                                                                    completion(nil)
                                                                })
                                                            })
                                                        }
                                                    }
                                                }
                                            }).resume()
                                        } else {
                                            presentAlert()
                                        }
                                    case .failed:
                                        presentAlert()
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
