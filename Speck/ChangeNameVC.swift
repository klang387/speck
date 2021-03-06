//
//  ChangeNameVC.swift
//  Speck
//
//  Created by Kevin Langelier on 9/9/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class ChangeNameVC: UIViewController {

    @IBOutlet weak var newUsername: UITextField!

    var delegate: ChangeNameDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        newUsername.attributedPlaceholder = NSAttributedString(string: "Enter New Username", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
    }

    @IBAction func savePressed(_ sender: Any) {
        newUsername.resignFirstResponder()
        delegate?.changeNameSavePressed()
        if let username = newUsername.text, let currentUser = Auth.auth().currentUser?.uid {
            guard username.count > 0 else {
                let alert = ErrorAlert(title: "Uh Oh", message: "Name is empty.", preferredStyle: .alert)
                present(alert, animated: true, completion: nil)
                return
            }
            guard !username.contains("@") else {
                let alert = ErrorAlert(title: "Uh Oh", message: "Name cannot contain '@'.", preferredStyle: .alert)
                present(alert, animated: true, completion: nil)
                return
            }
            DataService.instance.profilesRef.child(currentUser).updateChildValues(["name":username])
            delegate?.changeNameDismiss()
        }
    }

}

protocol ChangeNameDelegate {
    func changeNameDismiss()
    func changeNameSavePressed()
}
