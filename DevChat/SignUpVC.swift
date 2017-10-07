//
//  SignUpVC.swift
//  Speck
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
    var editLayer: CAShapeLayer!
    var label: UILabel!
    var keyboardHeight: CGFloat?
    var textFields: [UITextField]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        selectProfilePic.imageView?.contentMode = .scaleAspectFit
        selectProfilePic.imageView?.layer.cornerRadius = selectProfilePic.frame.width / 2
        selectProfilePic.imageView?.layer.masksToBounds = true
        selectProfilePic.setImage(UIImage(named: "UploadProfilePic"), for: .normal)
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        textFields = [firstName, lastName, email, password, passwordConfirm]
        firstName.delegate = self
        lastName.delegate = self
        email.delegate = self
        password.delegate = self
        passwordConfirm.delegate = self
        
        firstName.attributedPlaceholder = NSAttributedString(string: "First Name", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        lastName.attributedPlaceholder = NSAttributedString(string: "Last Name", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        email.attributedPlaceholder = NSAttributedString(string: "Email", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        password.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        passwordConfirm.attributedPlaceholder = NSAttributedString(string: "Re-Enter Password", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:))))
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: nil, completion: { _ in
            for field in self.textFields {
                if field.isFirstResponder {
                    self.view.animateViewMoving(textField: field, view: self.view)
                    return
                }
            }
        })
    }

    @IBAction func backBtnPressed(_ sender: Any) {
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func selectProfilePicPressed(_ sender: Any) {
        AppDelegate.AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func submitPressed(_ sender: Any) {
        guard let rootVC = UIApplication.shared.windows.last?.rootViewController else {return}
        guard firstName.text != nil && firstName.text != "" else {
            let alert = ErrorAlert(title: "First Name Required", message: "You must complete all fields to submit", preferredStyle: .alert)
            rootVC.present(alert, animated: true, completion: nil)
            return
        }
        guard lastName.text != nil && lastName.text != "" else {
            let alert = ErrorAlert(title: "Last Name Required", message: "You must complete all fields to submit", preferredStyle: .alert)
            rootVC.present(alert, animated: true, completion: nil)
            return
        }
        guard !firstName.text!.contains("@") && !lastName.text!.contains("@") else {
            let alert = ErrorAlert(title: "Invalid Name", message: "Names cannot contain '@' symbol", preferredStyle: .alert)
            rootVC.present(alert, animated: true, completion: nil)
            return
        }
        guard email.text != nil && email.text != "" else {
            let alert = ErrorAlert(title: "Email Required", message: "You must complete all fields to submit", preferredStyle: .alert)
            rootVC.present(alert, animated: true, completion: nil)
            return
        }
        guard email.text!.contains("@") && email.text!.contains(".") else {
            let alert = ErrorAlert(title: "Invalid Email", message: "Please enter a valid email address", preferredStyle: .alert)
            rootVC.present(alert, animated: true, completion: nil)
            return
        }
        guard password.text != nil && password.text != "" else {
            let alert = ErrorAlert(title: "Password Required", message: "You must complete all fields to submit", preferredStyle: .alert)
            rootVC.present(alert, animated: true, completion: nil)
            return
        }
        guard password.text == passwordConfirm.text else {
            let alert = ErrorAlert(title: "Password Confirmation Incorrect", message: "Your passwords do not match", preferredStyle: .alert)
            rootVC.present(alert, animated: true, completion: nil)
            return
        }
        guard selectProfilePic.image(for: .normal) != UIImage(named: "UploadProfilePic") else {
            let alert = ErrorAlert(title: "Profile Picture Required", message: "Please select a profile picture", preferredStyle: .alert)
            rootVC.present(alert, animated: true, completion: nil)
            return
        }
        
        AuthService.instance.createUser(email: self.email.text!, password: self.password.text!, completion: { (data, error) in
            if error != nil {
                let alert = ErrorAlert(title: "Uh Oh", message: "Couldn't finish setting up account.  Please check your internet connection and try again!", preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
            } else {
                if let imageData = UIImageJPEGRepresentation(self.selectProfilePic.imageView!.image!, 0.2) {
                    let imageName = NSUUID().uuidString
                    DataService.instance.profPicStorageRef.child(imageName).putData(imageData, metadata: StorageMetadata(), completion: { (metadata, error) in
                        if error != nil {
                            let alert = ErrorAlert(title: "Uh Oh", message: "Couldn't finish setting up account.  Please check your internet connection and try again!", preferredStyle: .alert)
                            self.present(alert, animated: true, completion: nil)
                        } else {
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
                    let alert = ErrorAlert(title: "Uh Oh", message: "Couldn't finish setting up account.  Please check your internet connection and try again!", preferredStyle: .alert)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        })
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            selectProfilePic.setImage(image, for: .normal)
        } else {
            let alert = ErrorAlert(title: "Error", message: "Invalid image.  Please try again.", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
        }
        imagePicker.dismiss(animated: true, completion: nil)
        AppDelegate.AppUtility.lockOrientation(.allButUpsideDown)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
        AppDelegate.AppUtility.lockOrientation(.allButUpsideDown)
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let imageVC = NSClassFromString("PUUIImageViewController")
        {
            if viewController.isKind(of: imageVC) {
                addRoundedEditLayer(to: viewController, forCamera: false)
            }
        }
    }
    
    func addRoundedEditLayer(to viewController: UIViewController, forCamera: Bool) {
        hideDefaultEditOverlay(view: viewController.view)
        
        let bottomBarHeight: CGFloat = 72.0
        let position = (forCamera) ? viewController.view.center.y - viewController.view.center.x - bottomBarHeight/2 : viewController.view.center.y - viewController.view.center.x
        
        let viewWidth = viewController.view.frame.width
        let viewHeight = viewController.view.frame.height
        
        let emptyShapePath = UIBezierPath(ovalIn: CGRect(x: 0, y: position, width: viewWidth, height: viewWidth))
        emptyShapePath.usesEvenOddFillRule = true
        
        let filledShapePath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight - bottomBarHeight), cornerRadius: 0)
        filledShapePath.append(emptyShapePath)
        filledShapePath.usesEvenOddFillRule = true
        
        editLayer = CAShapeLayer()
        editLayer.path = filledShapePath.cgPath
        editLayer.fillRule = kCAFillRuleEvenOdd
        editLayer.fillColor = UIColor.black.cgColor
        editLayer.opacity = 0.8
        viewController.view.layer.addSublayer(editLayer)
        
        label = UILabel(frame: CGRect(x: 0, y: 10, width: viewWidth, height: 50))
        label.text = "Move and Scale"
        label.textAlignment = .center
        label.textColor = UIColor.white
        viewController.view.addSubview(label)
    }
    
    func hideDefaultEditOverlay(view: UIView) {
        for subview in view.subviews {
            if let cropOverlay = NSClassFromString("PLCropOverlayCropView") {
                if subview.isKind(of: cropOverlay) {
                    subview.isHidden = true
                    break
                } else {
                    hideDefaultEditOverlay(view: subview)
                }
            }
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        view.animateViewMoving(textField: textField, view: view)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.animateViewMoving(textField: nil, view: view)
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case firstName:
            lastName.becomeFirstResponder()
        case lastName:
            email.becomeFirstResponder()
        case email:
            password.becomeFirstResponder()
        case password:
            passwordConfirm.becomeFirstResponder()
        case passwordConfirm:
            submitPressed(self)
        default: break
        }
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
}
