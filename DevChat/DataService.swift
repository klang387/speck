//
//  DataService.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/3/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import Foundation
import AVKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class DataService {
    private static let _instance = DataService()
    var _users = [User]()
    
    static var instance: DataService {
        return _instance
    }
    
    var users: [User] {
        return _users
    }
    
    var mainRef: DatabaseReference {
        return Database.database().reference()
    }
    
    var receivedSnapsRef: DatabaseReference {
        let user = Auth.auth().currentUser!.uid
        return usersRef.child(user).child("snapsReceived")
    }
    
    var usersRef: DatabaseReference {
        return mainRef.child("users")
    }
    
    var snapsRef: DatabaseReference {
        return mainRef.child("snaps")
    }
    
    var mainStorageRef: StorageReference {
        return Storage.storage().reference(forURL: "gs://devchat-9ca73.appspot.com/")
    }
    
    var mediaStorageRef: StorageReference {
        return mainStorageRef.child("media")
    }
    
    var profPicStorageRef: StorageReference {
        return mainStorageRef.child("profilePictures")
    }
    
    func saveUserToDatabase(uid: String, firstName: String, lastName: String, profPicUrl: String) {
        let profile = ["firstName": firstName, "lastName": lastName, "profPicUrl": profPicUrl]
        mainRef.child("users").child(uid).child("profile").updateChildValues(profile)
    }
    
    func loadUsers(completion: @escaping () -> Void) {
        self._users = []
        usersRef.observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
            if let users = snapshot.value as? Dictionary<String,Any> {
                for (key, value) in users {
                    if let dict = value as? Dictionary<String,Any> {
                        if let profile = dict["profile"] as? Dictionary<String,Any> {
                            if let firstName = profile["firstName"] as? String, let lastName = profile["lastName"] as? String, let profPicUrl = profile["profPicUrl"] as? String {
                                let uid = key
                                let user = User(uid: uid, firstName: firstName, lastName: lastName, profPicUrl: profPicUrl)
                                self._users.append(user)
                            }
                        }
                    }
                }
            }
            completion()
        }
    }
    
    func uploadMedia(tempVidUrl: URL?, tempPhotoData: Data?, caption: String?, recipients: [String:Bool], completion: () -> Void){
        let ref = mediaStorageRef.child("\(NSUUID().uuidString)")
        if let url = tempVidUrl {
            
            ref.putFile(from: url, metadata: nil, completion: { (meta: StorageMetadata?, err: Error?) in
                
                if err != nil {
                    print("Error uploading video: \(err!.localizedDescription)")
                } else {
                    if let downloadURL = meta?.downloadURL()?.absoluteString {
                        self.sendSnap(databaseUrl: downloadURL, caption: caption, recipients: recipients)
                    }
                }
            })
            
        } else if let photo = tempPhotoData {
            
            ref.putData(photo, metadata: nil, completion: { (meta: StorageMetadata?, err: Error?) in
                
                if err != nil {
                    print("Error uploading photo: \(err!.localizedDescription)")
                } else {
                    if let downloadURL = meta?.downloadURL()?.absoluteString {
                        self.sendSnap(databaseUrl: downloadURL, caption: caption, recipients: recipients)
                    }
                }
            })
        }
        
        completion()
    }
    
    func sendSnap(databaseUrl: String, caption: String?, recipients: [String:Bool]) {
        var snapDict = Dictionary<String,String>()
        snapDict["caption"] = caption
        snapDict["databaseUrl"] = databaseUrl
        snapDict["sender"] = Auth.auth().currentUser?.uid
        
        snapsRef.childByAutoId().setValue(snapDict) { (err, ref) in
            if err != nil {
                print("Error posting to database: \(err!.localizedDescription)")
            } else {
                print("Database post: \(ref.key)")
                for (key,_) in recipients {
                    self.usersRef.child(key).child("snapsReceived").child(ref.key).child("numOfViews").setValue(0)
                }
            }
        }
    }
    
    
}
