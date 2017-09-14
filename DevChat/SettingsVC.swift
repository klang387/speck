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
    @IBOutlet weak var friendsBadge: UILabel!
    @IBOutlet weak var topBar: UIImageView!
    
    var image: UIImage?
    var imagePicker: UIImagePickerController!
    private var editLayer: CAShapeLayer!
    private var label: UILabel!
    
    var changeNameVC: ChangeNameVC?
    var changePasswordVC: ChangePasswordVC?
    
    var currentView: String!
    var newViewStartFrame: CGRect!
    
    var friendsObserver: UInt!
    var requestCount: Int!
    var currentUser = String()
    
    var friendsVC: FriendsVC?
    
    var tapGesture: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        newViewStartFrame = CGRect(origin: CGPoint(x: view.frame.origin.x + view.frame.width, y: view.frame.origin.y), size: view.frame.size)
        
        profilePic.image = image
        profilePic.layer.cornerRadius = profilePic.frame.width / 2
        profilePic.layer.masksToBounds = true
        
        friendsBadge.layer.cornerRadius = friendsBadge.layer.frame.width / 2
        friendsBadge.layer.masksToBounds = true
        friendsBadge.text = String(requestCount)
        if requestCount > 0 {
            friendsBadge.isHidden = false
        }
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        
        tapGesture = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        self.view.addGestureRecognizer(tapGesture)
        
        currentView = "settings"
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let user = AuthService.instance.currentUser {
            currentUser = user
            friendsObserver = DataService.instance.usersRef.child(currentUser).child("friendRequests").observe(.value, with: { (snapshot) in
                if let friendRequests = snapshot.value as? [String:Any] {
                    self.friendsBadge.text = String(friendRequests.count)
                    self.friendsBadge.isHidden = false
                } else {
                    self.friendsBadge.isHidden = true
                }
            })
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        DataService.instance.usersRef.child(currentUser).child("friendRequests").removeObserver(withHandle: friendsObserver)
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
        tapGesture.isEnabled = false
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        friendsVC = storyboard.instantiateViewController(withIdentifier: "FriendsVC") as? FriendsVC
        addChildViewController(friendsVC!)
        friendsVC?.view.frame = newViewStartFrame
        view.insertSubview(friendsVC!.view, belowSubview: topBar)
        UIView.animate(withDuration: 0.3, animations: {
            self.friendsVC?.view.frame = self.view.frame
        }, completion: { (finished) in
            if finished {
                self.currentView = "friends"
            }
        })
    }

    @IBAction func backPressed(_ sender: Any) {
        switch currentView {
        case "settings":
            self.dismiss(animated: true, completion: nil)
        case "name":
            changeNameDismiss()
        case "password":
            changePasswordDismiss()
        case "friends":
            friendsDismiss()
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
    
    func friendsDismiss() {
        friendsVC?.searchBar.endEditing(true)
        UIView.animate(withDuration: 0.2, animations: {
            self.friendsVC?.view.frame.origin.x += self.view.frame.width
        }) { (finished) in
            self.friendsVC?.view.removeFromSuperview()
            self.friendsVC?.removeFromParentViewController()
            self.friendsVC = nil
        }
        currentView = "settings"
        tapGesture.isEnabled = true
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
