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

    @IBOutlet weak var firstName: RoundTextField!
    @IBOutlet weak var lastName: RoundTextField!
    @IBOutlet weak var email: RoundTextField!
    @IBOutlet weak var password: RoundTextField!
    @IBOutlet weak var passwordConfirm: RoundTextField!
    @IBOutlet weak var profilePicPreview: UIImageView!
    
    var imagePicker: UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
            profilePicPreview.image = image
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
            password.text == passwordConfirm.text {
            
            AuthService.instance.createUser(email: self.email.text!, password: self.password.text!, onComplete: { (error, data) in
                if error != nil {
                    print("Error creating user: \(error!.debugDescription)")
                } else {
                    print("Firebase user created successfully")
                    if let imageData = UIImageJPEGRepresentation(self.profilePicPreview.image!, 0.2) {
                        DataService.instance.profPicStorageRef.child("\(NSUUID().uuidString)").putData(imageData, metadata: StorageMetadata(), completion: { (metadata, error) in
                            if error != nil {
                                print("Image upload to Firebase failed: \(error.debugDescription)")
                                return
                            } else {
                                print("Image uploaded to Firebase successful.")
                                if let downloadURL = metadata?.downloadURL()?.absoluteString {
                                    if let uid = Auth.auth().currentUser?.uid {
                                        DataService.instance.saveUserToDatabase(uid: uid, firstName: self.firstName.text!, lastName: self.lastName.text!, profPicUrl: downloadURL)
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
