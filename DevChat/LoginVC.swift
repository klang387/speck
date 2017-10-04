//
//  LoginVC.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/2/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit
import Firebase
import FacebookCore
import FacebookLogin

class LoginVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailField.delegate = self
        passwordField.delegate = self
        
        emailField.attributedPlaceholder = NSAttributedString(string: "Enter email", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        passwordField.attributedPlaceholder = NSAttributedString(string: "Enter password", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:))))
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if UIDevice.current.userInterfaceIdiom == .pad && view.bounds.width > view.bounds.height {
            backgroundImage.image = UIImage(named: "SignInBgIpadLandscape")
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            backgroundImage.image = UIImage(named: "SignInBgIpad")
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.animateViewMoving(up: true, moveValue: 150, view: self.view)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.animateViewMoving(up: false, moveValue: 150, view: self.view)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }

    @IBAction func forgotPasswordPressed(_ sender: Any) {
        let passwordReset = UIAlertController(title: "Forgot Your Password?", message: "No problem.  Enter your email and we'll help you reset it.", preferredStyle: .alert)
        passwordReset.addTextField()
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [unowned passwordReset] _ in
            if let email = passwordReset.textFields![0].text {
                Auth.auth().sendPasswordReset(withEmail: email, completion: nil)
                passwordReset.dismiss(animated: true, completion: nil)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        passwordReset.addAction(submitAction)
        passwordReset.addAction(cancelAction)
        present(passwordReset, animated: true, completion: nil)
    }
    
    @IBAction func facebookLoginPressed(_ sender: Any) {
        AuthService.instance.facebookLogin(completion: {
            self.dismiss(animated: true, completion: nil)
            UserDefaults.standard.set(true, forKey: "facebookLogin")
            AppDelegate.AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
        })
    }
    
    @IBAction func loginPressed(_ sender: Any) {
        if let email = emailField.text, let pass = passwordField.text, (email.characters.count > 0 && pass.characters.count > 0) {
            
            AuthService.instance.emailSignIn(email: email, password: pass, completion: { (user, error) in
                if error != nil {
                    let alert = UIAlertController(title: "Error Authenticating", message: error, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                AppDelegate.AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
                self.dismiss(animated: true, completion: nil)
            })
            
        } else {
            let alert = ErrorAlert(title: "Username and Password Required", message: "You must enter both a username and a password", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func createAccountPressed(_ sender: Any) {
        performSegue(withIdentifier: "toSignUpVC", sender: nil)
    }
}
