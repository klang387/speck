//
//  ChangePasswordVC.swift
//  DevChat
//
//  Created by Kevin Langelier on 9/9/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit
import FirebaseAuth

class ChangePasswordVC: UIViewController {

    @IBOutlet weak var oldPassword: UITextField!
    @IBOutlet weak var newPassword: UITextField!
    @IBOutlet weak var repeatNewPassword: UITextField!
    
    var delegate: ChangePasswordDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func savePressed(_ sender: Any) {
        if let oldPassword = oldPassword.text, let newPassword = newPassword.text, let repeatNewPassword = repeatNewPassword.text {
            if oldPassword.characters.count > 0 &&
                newPassword.characters.count > 0 &&
                repeatNewPassword == newPassword {
                guard let email = Auth.auth().currentUser?.email else {return}
                let credential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
                Auth.auth().currentUser?.reauthenticate(with: credential, completion: { (error) in
                    if error != nil {
                        print("Incorrect old password")
                    } else {
                        Auth.auth().currentUser?.updatePassword(to: self.newPassword.text!, completion: { (error) in
                            if error != nil {
                                print("Error updating password: \(error)")
                            } else {
                                self.delegate?.changePasswordDismiss()
                            }
                        })
                    }
                })
            }
        }
    }
    
}

protocol ChangePasswordDelegate {
    func changePasswordDismiss()
}