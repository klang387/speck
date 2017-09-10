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

class SettingsVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, ChangePasswordDelegate, ChangeNameDelegate {

    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var buttonsView: UIView!
    
    var image: UIImage?
    var imagePicker: UIImagePickerController!
    
    var changeNameVC: ChangeNameVC?
    var changePasswordVC: ChangePasswordVC?
    
    var currentView: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profilePic.image = image
        profilePic.layer.cornerRadius = profilePic.frame.width / 2
        profilePic.layer.masksToBounds = true
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:))))
        
        currentView = "settings"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    
    @IBAction func changePhotoPressed(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }

    @IBAction func changeNamePressed(_ sender: Any) {
        currentView = "name"
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "ChangeNameVC") as? ChangeNameVC else {return}
        changeNameVC = controller
        addChildViewController(changeNameVC!)
        changeNameVC?.view.frame = buttonsView.frame
        changeNameVC?.view.frame.origin.x += view.frame.width
        view.addSubview(changeNameVC!.view)
        changeNameVC?.delegate = self
        changeNameVC?.newUsername.delegate = self
        UIView.animate(withDuration: 0.2, animations: {
            self.buttonsView.frame.origin.x -= self.view.frame.width
            self.changeNameVC?.view.frame.origin.x -= self.view.frame.width
        }) { (finished) in
            
        }
    }
    
    @IBAction func changePasswordPressed(_ sender: Any) {
        if Auth.auth().currentUser?.email != nil {
            currentView = "password"
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let controller = storyboard.instantiateViewController(withIdentifier: "ChangePasswordVC") as? ChangePasswordVC else {return}
            changePasswordVC = controller
            addChildViewController(changePasswordVC!)
            changePasswordVC?.view.frame = buttonsView.frame
            changePasswordVC?.view.frame.origin.x += view.frame.width
            view.addSubview(changePasswordVC!.view)
            changePasswordVC?.delegate = self
            changePasswordVC?.oldPassword.delegate = self
            changePasswordVC?.newPassword.delegate = self
            changePasswordVC?.repeatNewPassword.delegate = self
            UIView.animate(withDuration: 0.2, animations: {
                self.buttonsView.frame.origin.x -= self.view.frame.width
                self.changePasswordVC?.view.frame.origin.x -= self.view.frame.width
            }) { (finished) in
                
            }
        } else {
            print("User logged in with Facebook")
        }
    }
    
    @IBAction func friendsPressed(_ sender: Any) {
        performSegue(withIdentifier: "toFriendsVC", sender: nil)
    }

    @IBAction func backPressed(_ sender: Any) {
        switch currentView {
        case "settings":
            self.dismiss(animated: true, completion: nil)
        case "name":
            changeNameDismiss()
        case "password":
            changePasswordDismiss()
        default: break
        }
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
                            DataService.instance.saveLocalProfilePic(imageData: imageData)
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
    
    func changePasswordDismiss() {
        UIView.animate(withDuration: 0.2, animations: {
            self.buttonsView.frame.origin.x += self.view.frame.width
            self.changePasswordVC?.view.frame.origin.x += self.view.frame.width
        }) { (finished) in
            self.changePasswordVC?.view.removeFromSuperview()
            self.changePasswordVC?.removeFromParentViewController()
        }
        currentView = "settings"
    }
    
    func changeNameDismiss() {
        UIView.animate(withDuration: 0.2, animations: {
            self.buttonsView.frame.origin.x += self.view.frame.width
            self.changeNameVC?.view.frame.origin.x += self.view.frame.width
        }) { (finished) in
            self.changeNameVC?.view.removeFromSuperview()
            self.changeNameVC?.removeFromParentViewController()
        }
        currentView = "settings"
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.animateViewMoving(up: true, moveValue: 75, view: self.view)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.animateViewMoving(up: false, moveValue: 75, view: self.view)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }

    
}
