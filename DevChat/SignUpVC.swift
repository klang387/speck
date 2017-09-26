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
    private var editLayer: CAShapeLayer!
    private var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        selectProfilePic.imageView?.contentMode = .scaleAspectFit
        selectProfilePic.imageView?.layer.cornerRadius = selectProfilePic.frame.width / 2
        selectProfilePic.imageView?.layer.masksToBounds = true
        selectProfilePic.setImage(UIImage(named: "UploadProfilePic"), for: .normal)
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        firstName.delegate = self
        lastName.delegate = self
        email.delegate = self
        password.delegate = self
        passwordConfirm.delegate = self
        
        firstName.attributedPlaceholder = NSAttributedString(string: "First Name", attributes: [NSForegroundColorAttributeName: UIColor.white])
        lastName.attributedPlaceholder = NSAttributedString(string: "Last Name", attributes: [NSForegroundColorAttributeName: UIColor.white])
        email.attributedPlaceholder = NSAttributedString(string: "Email", attributes: [NSForegroundColorAttributeName: UIColor.white])
        password.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [NSForegroundColorAttributeName: UIColor.white])
        passwordConfirm.attributedPlaceholder = NSAttributedString(string: "Re-Enter Password", attributes: [NSForegroundColorAttributeName: UIColor.white])
        
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
        } else {
            print("Failed to select valid image")
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
    
    private func addRoundedEditLayer(to viewController: UIViewController, forCamera: Bool) {
        hideDefaultEditOverlay(view: viewController.view)
        
        // Circle in edit layer - y position
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
        
        // Move and Scale label
        label = UILabel(frame: CGRect(x: 0, y: 10, width: viewWidth, height: 50))
        label.text = "Move and Scale"
        label.textAlignment = .center
        label.textColor = UIColor.white
        viewController.view.addSubview(label)
    }
    
    
    private func hideDefaultEditOverlay(view: UIView) {
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

    @IBAction func backBtnPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func selectProfilePicPressed(_ sender: Any) {
        AppDelegate.AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func submitPressed(_ sender: Any) {
        guard firstName.text != nil && firstName.text != "" else {
            let alert = ErrorAlert(title: "First Name Required", message: "You must complete all fields to submit", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
            return
        }
        guard lastName.text != nil && lastName.text != "" else {
            let alert = ErrorAlert(title: "Last Name Required", message: "You must complete all fields to submit", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
            return
        }
        guard !firstName.text!.contains("@") && !lastName.text!.contains("@") else {
            let alert = ErrorAlert(title: "Invalid Name", message: "Names cannot contain '@' symbol", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
            return
        }
        guard email.text != nil && email.text != "" else {
            let alert = ErrorAlert(title: "Email Required", message: "You must complete all fields to submit", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
            return
        }
        guard email.text!.contains("@") && email.text!.contains(".") else {
            let alert = ErrorAlert(title: "Invalid Email", message: "Please enter a valid email address", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
            return
        }
        guard password.text != nil && password.text != "" else {
            let alert = ErrorAlert(title: "Password Required", message: "You must complete all fields to submit", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
            return
        }
        guard password.text == passwordConfirm.text else {
            let alert = ErrorAlert(title: "Password Confirmation Incorrect", message: "Your passwords do not match", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
            return
        }
        guard selectProfilePic.image(for: .normal) != UIImage(named: "UploadProfilePic") else {
            let alert = ErrorAlert(title: "Profile Picture Required", message: "Please select a profile picture", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
            return
        }
        
        AuthService.instance.createUser(email: self.email.text!, password: self.password.text!, completion: { (data, error) in
            if error != nil {
                print("Error creating user: \(error!.debugDescription)")
            } else {
                if let imageData = UIImageJPEGRepresentation(self.selectProfilePic.imageView!.image!, 0.2) {
                    let imageName = NSUUID().uuidString
                    DataService.instance.profPicStorageRef.child(imageName).putData(imageData, metadata: StorageMetadata(), completion: { (metadata, error) in
                        if error != nil {
                            print("Image upload to Firebase failed: \(error.debugDescription)")
                            return
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
                    print("Error converting profile picture")
                }
            }
        })
        
    }
    
}
