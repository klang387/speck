//
//  ChangePasswordVC.swift
//  Speck
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
        
        oldPassword.attributedPlaceholder = NSAttributedString(string: "Old Password", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        newPassword.attributedPlaceholder = NSAttributedString(string: "New Password", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        repeatNewPassword.attributedPlaceholder = NSAttributedString(string: "Repeat New Password", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
    }

    @IBAction func savePressed(_ sender: Any) {
        for field in [oldPassword, newPassword, repeatNewPassword] {
            if field!.isFirstResponder {
                field?.resignFirstResponder()
                delegate?.changePasswordSavePressed()
            }
        }
        if let oldPassword = oldPassword.text, let newPassword = newPassword.text, let repeatNewPassword = repeatNewPassword.text {
            guard !oldPassword.isEmpty && !newPassword.isEmpty else {
                let alert = ErrorAlert(title: "Uh Oh", message: "All fields are required.", preferredStyle: .alert)
                present(alert, animated: true, completion: nil)
                return
            }
            guard newPassword == repeatNewPassword else {
                let alert = ErrorAlert(title: "Uh Oh", message: "Passwords don't match.", preferredStyle: .alert)
                present(alert, animated: true, completion: nil)
                return
            }
            guard let email = Auth.auth().currentUser?.email else {return}
            let credential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
            Auth.auth().currentUser?.reauthenticate(with: credential, completion: { error in
                if error != nil {
                    let alert = ErrorAlert(title: "Uh Oh", message: error?.localizedDescription, preferredStyle: .alert)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    Auth.auth().currentUser?.updatePassword(to: self.newPassword.text!, completion: { (error) in
                        if error != nil {
                            let alert = ErrorAlert(title: "Uh Oh", message: "Couldn't change password.  Please check your internet connection and try again!", preferredStyle: .alert)
                            self.present(alert, animated: true, completion: nil)
                        } else {
                            self.delegate?.changePasswordDismiss()
                        }
                    })
                }
            })
        }
    }
    
}

protocol ChangePasswordDelegate {
    func changePasswordDismiss()
    func changePasswordSavePressed()
}
