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
    
    var friendsRef: DatabaseReference {
        let user = Auth.auth().currentUser!.uid
        return usersRef.child(user).child("friends")
    }
    
    var friendRequestsRef: DatabaseReference {
        let user = Auth.auth().currentUser!.uid
        return usersRef.child(user).child("friendRequests")
    }
    
    var usersRef: DatabaseReference {
        return mainRef.child("users")
    }
    
    var profilesRef: DatabaseReference {
        return mainRef.child("profiles")
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
        let profile = ["name": "\(firstName) \(lastName)", "profPicUrl": profPicUrl]
        mainRef.child("profiles").child(uid).updateChildValues(profile)
    }
    
    func loadUsers(snapshot: DataSnapshot) -> [User] {
        var userArray: [User] = []
        if let users = snapshot.value as? [String:Any] {
            print("Converting snapshot success")
            for (key, value) in users {
                if let dict = value as? [String:Any] {
                    if let name = dict["name"] as? String, let profPicUrl = dict["profPicUrl"] as? String {
                        let user = User(uid: key, name: name, profPicUrl: profPicUrl)
                        userArray.append(user)
                    }
                }
            }
            return userArray
        } else {
            print("Converting snapshot to dictionary failed.")
            return []
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
                        self.sendSnap(databaseUrl: downloadURL, mediaType: "video", caption: caption, recipients: recipients)
                    }
                }
            })
            
        } else if let photo = tempPhotoData {
            
            ref.putData(photo, metadata: nil, completion: { (meta: StorageMetadata?, err: Error?) in
                
                if err != nil {
                    print("Error uploading photo: \(err!.localizedDescription)")
                } else {
                    if let downloadURL = meta?.downloadURL()?.absoluteString {
                        self.sendSnap(databaseUrl: downloadURL, mediaType: "photo", caption: caption, recipients: recipients)
                    }
                }
            })
        }
        
        completion()
    }
    
    func sendSnap(databaseUrl: String, mediaType: String, caption: String?, recipients: [String:Bool]) {
        
        var snapDict = [String:Any]()
        
        var currentUser = String()
        if let user = Auth.auth().currentUser?.uid {
            currentUser = user
        } else {
            print("Error getting current user")
            return
        }
        
        snapDict["caption"] = caption
        snapDict["databaseUrl"] = databaseUrl
        snapDict["mediaType"] = mediaType
        snapDict["timestamp"] = ServerValue.timestamp()
        
        for (key,_) in recipients {
            self.usersRef.child(key).child("snapsReceived").child(currentUser).child("snaps").childByAutoId().setValue(snapDict) { (err, ref) in
                if err != nil {
                    print("Error posting to database: \(err!.localizedDescription)")
                    return
                }
            }
            self.usersRef.child(key).child("snapsReceived").child(currentUser).child("mostRecent").setValue(ServerValue.timestamp()) { (err,ref) in
                if err != nil {
                    print("Error posting to database: \(err!.localizedDescription)")
                    return
                }
            }
        }
    }
    
    
}
