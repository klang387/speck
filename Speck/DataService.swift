//
//  DataService.swift
//  Speck
//
//  Created by Kevin Langelier on 8/3/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import AVKit
import FirebaseDatabase
import FirebaseStorage

class DataService {
    private static let _instance = DataService()
    
    static var instance: DataService {
        return _instance
    }
    
    var mainRef: DatabaseReference {
        return Database.database().reference()
    }
    
    var receivedSnapsRef: DatabaseReference {
        return usersRef.child(AuthService.instance.currentUser).child("snapsReceived")
    }
    
    var friendsRef: DatabaseReference {
        return usersRef.child(AuthService.instance.currentUser).child("friends")
    }
    
    var friendRequestsRef: DatabaseReference {
        return usersRef.child(AuthService.instance.currentUser).child("friendRequests")
    }
    
    var outgoingRequestsRef: DatabaseReference {
        return usersRef.child(AuthService.instance.currentUser).child("outgoingRequests")
    }
    
    var usersRef: DatabaseReference {
        return mainRef.child("users")
    }
    
    var profilesRef: DatabaseReference {
        return mainRef.child("profiles")
    }
    
    var tokensRef: DatabaseReference {
        return usersRef.child(AuthService.instance.currentUser).child("tokens")
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
    
    var documentsUrl: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func addToken() {
        tokensRef.child(AuthService.instance.fcmToken).setValue(true)
    }
    
    func removeToken() {
        tokensRef.child(AuthService.instance.fcmToken).removeValue()
    }
    
    func saveUserToDatabase(uid: String, firstName: String, lastName: String, profPicUrl: String, email: String) {
        let profile = ["name": "\(firstName) \(lastName)", "profPicUrl": profPicUrl]
        let emailRef = [uid:email.lowercased()]
        mainRef.child("profiles").child(uid).updateChildValues(profile)
        mainRef.child("emails").updateChildValues(emailRef)
    }
    
    func loadUsersFromSnapshot(snapshot: DataSnapshot, completion: @escaping ([User]) -> Void) {
        var userArray: [User] = []
        if let users = snapshot.value as? [String:Any] {
            for (key,_) in users {
                self.profilesRef.child(key).observeSingleEvent(of: .value, with: { (snapshot2) in
                    if let profile = snapshot2.value as? [String:String] {
                        if let name = profile["name"], let profPicUrl = profile["profPicUrl"] {
                            let user = User(uid: key, name: name, profPicUrl: profPicUrl)
                            userArray.append(user)
                            if userArray.count == users.keys.count {
                                completion(userArray)
                            }
                        }
                    }
                })
            }
        } else {
            completion(userArray)
        }
    }
    
    func searchDatabaseForUser(searchTerm: String, completion: @escaping ([User]) -> Void) {
        var userArray: [User] = []
        let url = URL(string: "https://us-central1-devchat-9ca73.cloudfunctions.net/findUser?name=" + searchTerm)
        let task = URLSession.shared.dataTask(with: url!) {data, response, error in
            guard error == nil else {
                completion(userArray)
                return
            }
            guard let data = data else {
                completion(userArray)
                return
            }
            let json = try! JSONSerialization.jsonObject(with: data, options: [])
            if let uidArray = json as? [String] {
                guard !uidArray.isEmpty else {
                    completion(userArray)
                    return
                }
                for uid in uidArray {
                    self.profilesRef.child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
                        if let profile = snapshot.value as? [String:String] {
                            if let name = profile["name"], let profPicUrl = profile["profPicUrl"] {
                                let user = User(uid: uid, name: name, profPicUrl: profPicUrl)
                                userArray.append(user)
                                if userArray.count == uidArray.count {
                                    completion(userArray)
                                }
                            }
                        }
                    })
                }
            } else {
                completion(userArray)
            }
        }
        task.resume()
    }
    
    func searchUsersByEmail(searchTerm: String, handler: @escaping ([User]) -> Void) {
        self.mainRef.child("emails").queryOrderedByValue().queryEqual(toValue: searchTerm.lowercased()).observeSingleEvent(of: .value, with: { (snapshot) in
            self.loadUsersFromSnapshot(snapshot: snapshot, completion: { (users) in
                let array = users
                handler(array)
            })
        })
    }
    
    func loadAllUsers(snapshot: DataSnapshot) -> [User] {
        var userArray: [User] = []
        let sortedArray = snapshot.children.allObjects as! [DataSnapshot]
        for user in sortedArray {
            if let dict = user.value as? [String:Any] {
                if let name = dict["name"] as? String, let profPicUrl = dict["profPicUrl"] as? String {
                    let user = User(uid: user.key, name: name, profPicUrl: profPicUrl)
                    userArray.append(user)
                }
            }
        }
        return userArray
    }
    
    func uploadMedia(storageName: String, tempVidUrl: URL?, tempPhotoData: Data?, caption: [String:Any]?, recipients: [String:Bool], completion: @escaping (String?, ErrorAlert?) -> Void){
        let ref = mediaStorageRef.child(storageName)
        if let url = tempVidUrl {
            ref.putFile(from: url, metadata: nil, completion: { (meta: StorageMetadata?, err: Error?) in
                if err != nil {
                    let alert = ErrorAlert(title: "Uh Oh", message: "Trouble uploading video.  Please check your internet connection and try again!", preferredStyle: .alert)
                    completion(nil, alert)
                    return
                } else {
                    ref.downloadURL(completion: { (url, error) in
                        if let downloadURL = url?.absoluteString {
                            completion(downloadURL, nil)
                            self.sendSnap(storageName: storageName, databaseUrl: downloadURL, mediaType: "video", caption: caption, recipients: recipients, completion: { errorAlert in
                                if let alert = errorAlert {
                                    completion(nil, alert)
                                }
                            })
                        }
                    })
                }
            })
            
        } else if let photo = tempPhotoData {
            ref.putData(photo, metadata: nil, completion: { (meta: StorageMetadata?, err: Error?) in
                if err != nil {
                    let alert = ErrorAlert(title: "Uh Oh", message: "Trouble uploading video.  Please check your internet connection and try again!", preferredStyle: .alert)
                    completion(nil, alert)
                    return
                } else {
                    ref.downloadURL(completion: { (url, error) in
                        if let downloadURL = url?.absoluteString {
                            completion(downloadURL, nil)
                            self.sendSnap(storageName: storageName, databaseUrl: downloadURL, mediaType: "photo", caption: caption, recipients: recipients, completion: { errorAlert in
                                if let alert = errorAlert {
                                    completion(nil,alert)
                                }
                            })
                        }
                    })
                }
            })
        }
    }
    
    func sendSnap(storageName: String, databaseUrl: String, mediaType: String, caption: [String:Any]?, recipients: [String:Bool], completion: @escaping (ErrorAlert?) -> Void) {
        var snapDict = [String:Any]()
        let currentUser = AuthService.instance.currentUser
        
        if let captionText = caption?["text"] as? String, let captionPosY = caption?["yPos"] as? CGFloat {
            snapDict["captionText"] = captionText
            snapDict["captionPosY"] = captionPosY
        }
        snapDict["databaseUrl"] = databaseUrl
        snapDict["mediaType"] = mediaType
        snapDict["timestamp"] = ServerValue.timestamp()
        snapDict["storageName"] = storageName
        
        for (key,_) in recipients {
            self.usersRef.child(key).child("snapsReceived").child(currentUser).child("snaps").childByAutoId().setValue(snapDict) { (err, ref) in
                if err != nil {
                    let alert = ErrorAlert(title: "Uh Oh", message: "Trouble sending media.  Please check your internet connection and try again!", preferredStyle: .alert)
                    completion(alert)
                    return
                }
            }
            self.usersRef.child(key).child("snapsReceived").child(currentUser).child("mostRecent").setValue(ServerValue.timestamp()) { (err,ref) in
                if err != nil {
                    let alert = ErrorAlert(title: "Uh Oh", message: "Trouble sending media.  Please check your internet connection and try again!", preferredStyle: .alert)
                    completion(alert)
                    return
                }
            }
        }
        
        mainRef.child("viewCounts").child(storageName).observeSingleEvent(of: .value, with: { (snapshot) in
            var viewCount = recipients.count
            if let existingCount = snapshot.value as? Int {
                viewCount += existingCount
            }
            self.mainRef.child("viewCounts").child(storageName).setValue(viewCount)
        })
    }
    
    func saveLocalProfilePic(imageData: Data) {
        let fileURL = documentsUrl.appendingPathComponent("profilePic")
        try? FileManager.default.removeItem(at: fileURL)
        try? imageData.write(to: fileURL, options: .atomic)
    }
    
    func loadLocalProfilePic() -> UIImage? {
        let fileURL = documentsUrl.appendingPathComponent("profilePic")
        do {
            let imageData = try Data(contentsOf: fileURL)
            return UIImage(data: imageData)
        } catch {
            return nil
        }
    }
    
    func removeLocalProfilePic() {
        let fileURL = documentsUrl.appendingPathComponent("profilePic")
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    
}
