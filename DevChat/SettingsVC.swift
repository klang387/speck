//
//  SettingsVC.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/17/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseStorage

class SettingsVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var buttonsView: UIView!
    
    var image: UIImage?
    var imagePicker: UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profilePic.image = image
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    
    @IBAction func changePhotoPressed(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }

    @IBAction func changeNamePressed(_ sender: Any) {
        
    }
    
    @IBAction func changePasswordPressed(_ sender: Any) {
        
    }
    
    @IBAction func friendsPressed(_ sender: Any) {
        performSegue(withIdentifier: "toFriendsVC", sender: nil)
    }

    @IBAction func backPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func signOutPressed(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            weak var cameraVC = self.presentingViewController
            self.dismiss(animated: true) {
                cameraVC?.performSegue(withIdentifier: "toLoginVC", sender: nil)
            }
        } catch {
            print("Sign out failed")
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            profilePic.image = image
            if let imageData = UIImageJPEGRepresentation(image, 0.2) {
                if let currentUser = Auth.auth().currentUser?.uid {
                    DataService.instance.usersRef.child(currentUser).child("profPicStorageRef").observeSingleEvent(of: .value, with: { (snapshot) in
                        if let profPicStorageRef = snapshot.value as? String {
                            DataService.instance.profPicStorageRef.child(profPicStorageRef).delete(completion: { (error) in
                                if error != nil {
                                    print("Error deleting profile pic: \(error)")
                                }
                            })
                        } else {
                            print("Failed to get profPicStorageRef")
                        }
                    })
                    let imageName = NSUUID().uuidString
                    DataService.instance.profPicStorageRef.child(imageName).putData(imageData, metadata: StorageMetadata(), completion: { (metadata, error) in
                        if let downloadURL = metadata?.downloadURL()?.absoluteString {
                            DataService.instance.profilesRef.child(currentUser).updateChildValues(["profPicUrl":downloadURL])
                            print("Successfully changed image")
                        } else {
                            print("Failed to get downloadUrl")
                        }
                    })
                } else {
                    print("Failed to upload image")
                }
            } else {
                print("Failed to create JPEG")
            }
        } else {
            print("Failed to select valid image")
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    

    
}
