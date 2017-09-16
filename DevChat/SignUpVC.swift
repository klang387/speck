//
//  SignUpVC.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/17/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseAuth

class SignUpVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var passwordConfirm: UITextField!
    @IBOutlet weak var selectProfilePic: UIButton!
    
    var imagePicker: UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        selectProfilePic.imageView?.contentMode = .scaleAspectFit
        selectProfilePic.setImage(UIImage(named: "UploadProfilePic"), for: .normal)
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        firstName.delegate = self
        lastName.delegate = self
        email.delegate = self
        password.delegate = self
        passwordConfirm.delegate = self
        
        
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:))))
        
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            selectProfilePic.setImage(image, for: .normal)
            if let imageData = UIImageJPEGRepresentation(image, 0.2) {
                DataService.instance.saveLocalProfilePic(imageData: imageData)
            }
        } else {
            print("Failed to select valid image")
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }

    @IBAction func backBtnPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func selectProfilePicPressed(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func submitPressed(_ sender: Any) {
        if (firstName.text?.characters.count)! > 0 &&
            (lastName.text?.characters.count)! > 0 &&
            (email.text?.characters.count)! > 0 &&
            (password.text?.characters.count)! > 0 &&
            password.text == passwordConfirm.text &&
            selectProfilePic.image(for: .normal) != UIImage(named: "UploadProfilePic") {
            
            AuthService.instance.createUser(email: self.email.text!, password: self.password.text!, completion: { (data, error) in
                if error != nil {
                    print("Error creating user: \(error!.debugDescription)")
                } else {
                    print("Firebase user created successfully")
                    if let imageData = UIImageJPEGRepresentation(self.selectProfilePic.imageView!.image!, 0.2) {
                        let imageName = NSUUID().uuidString
                        DataService.instance.profPicStorageRef.child(imageName).putData(imageData, metadata: StorageMetadata(), completion: { (metadata, error) in
                            if error != nil {
                                print("Image upload to Firebase failed: \(error.debugDescription)")
                                return
                            } else {
                                print("Image uploaded to Firebase successful.")
                                if let downloadURL = metadata?.downloadURL()?.absoluteString {
                                    if let uid = Auth.auth().currentUser?.uid, let email = Auth.auth().currentUser?.email {
                                        DataService.instance.saveUserToDatabase(uid: uid, firstName: self.firstName.text!.capitalized, lastName: self.lastName.text!.capitalized, profPicUrl: downloadURL, email: email)
                                        DataService.instance.usersRef.child(uid).child("profPicStorageRef").setValue(imageName)
                                        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
                                    }
                                }
                            }
                            
                        })
                    } else {
                        print("Error converting profile picture")
                    }
                }
            })
            
        }
        
    }
    
}
