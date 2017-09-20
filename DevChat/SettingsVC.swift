//
//  SettingsVC.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/17/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseAuth

class SettingsVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, ChangePasswordDelegate, ChangeNameDelegate {

    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var buttonsView: UIView!
    @IBOutlet weak var friendsBadge: UILabel!
    @IBOutlet weak var topBar: UIImageView!
    
    @IBOutlet weak var buttonsViewLeading: NSLayoutConstraint!
    @IBOutlet weak var buttonsViewTrailing: NSLayoutConstraint!
    
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
    var currentUser: String!
    
    var friendsVC: FriendsVC?
    
    var tapGesture: UITapGestureRecognizer!
    
    var constraintLeading: NSLayoutConstraint?
    var constraintTrailing: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        currentUser = AuthService.instance.currentUser
        
        profilePic.image = image
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
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        friendsObserver = DataService.instance.usersRef.child(currentUser).child("friendRequests").observe(.value, with: { (snapshot) in
            if let friendRequests = snapshot.value as? [String:Any] {
                self.friendsBadge.text = String(friendRequests.count)
                self.friendsBadge.isHidden = false
            } else {
                self.friendsBadge.isHidden = true
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        DataService.instance.usersRef.child(currentUser).child("friendRequests").removeObserver(withHandle: friendsObserver)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if currentView == "name" && buttonsViewTrailing.constant != 0 {
            buttonsViewLeading.constant = -view.frame.width
            buttonsViewTrailing.constant = view.frame.width
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("layoutSubviews")
        
        profilePic.layer.cornerRadius = profilePic.frame.width / 2
        newViewStartFrame = CGRect(origin: CGPoint(x: view.frame.origin.x + view.frame.width, y: view.frame.origin.y), size: view.frame.size)
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

    func animateButtonsIn(controller: UIViewController) {
        addChildViewController(controller)
        view.addSubview(controller.view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        constraintLeading = controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: self.view.frame.width)
        constraintLeading?.isActive = true
        constraintTrailing = controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -self.view.frame.width)
        constraintTrailing?.isActive = true
        controller.view.topAnchor.constraint(equalTo: buttonsView.topAnchor, constant: 0).isActive = true
        controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40).isActive = true
        let distance = view.frame.width > view.frame.height ? view.frame.width : view.frame.height
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.2, animations: {
            self.buttonsViewLeading.constant -= distance
            self.buttonsViewTrailing.constant += distance
            self.constraintLeading?.constant = 0
            self.constraintTrailing?.constant = 0
            self.view.layoutIfNeeded()
        }) { (finished) in

        }
    }
    
    func animateButtonsOut(controller: UIViewController) {
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.2, animations: { 
            self.buttonsViewLeading.constant = 0
            self.buttonsViewTrailing.constant = 0
            self.constraintLeading?.constant = self.view.frame.width
            self.constraintTrailing?.constant = -self.view.frame.width
            self.view.layoutIfNeeded()
        }) { (finished) in
            self.currentView = "settings"
            self.constraintLeading = nil
            self.constraintTrailing = nil
            self.changeNameVC?.view.removeFromSuperview()
            self.changeNameVC?.removeFromParentViewController()
            self.changeNameVC = nil
            self.changePasswordVC?.view.removeFromSuperview()
            self.changePasswordVC?.removeFromParentViewController()
            self.changePasswordVC = nil
        }
    }
    
    @IBAction func changeNamePressed(_ sender: Any) {
        currentView = "name"
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        changeNameVC = (storyboard.instantiateViewController(withIdentifier: "ChangeNameVC") as! ChangeNameVC)
        changeNameVC?.delegate = self
        changeNameVC?.newUsername?.delegate = self
        animateButtonsIn(controller: changeNameVC!)
    }
    
    @IBAction func changePasswordPressed(_ sender: Any) {
        if Auth.auth().currentUser?.email != nil {
            currentView = "password"
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            changePasswordVC = (storyboard.instantiateViewController(withIdentifier: "ChangePasswordVC") as! ChangePasswordVC)
            changePasswordVC?.delegate = self
            changePasswordVC?.oldPassword?.delegate = self
            changePasswordVC?.newPassword?.delegate = self
            changePasswordVC?.repeatNewPassword?.delegate = self
            animateButtonsIn(controller: changePasswordVC!)
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
            AppDelegate.AppUtility.lockOrientation(.portrait)
            self.dismiss(animated: true, completion: nil)
        case "name":
            animateButtonsOut(controller: changeNameVC!)
        case "password":
            animateButtonsOut(controller: changePasswordVC!)
        case "friends":
            friendsDismiss()
        default: break
        }
    }
    
    @IBAction func signOutPressed(_ sender: Any) {
        do {
            DataService.instance.removeToken()
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
                DataService.instance.usersRef.child(currentUser).child("profPicStorageRef").observeSingleEvent(of: .value, with: { (snapshot) in
                    if let profPicStorageRef = snapshot.value as? String {
                        DataService.instance.profPicStorageRef.child(profPicStorageRef).delete(completion: { (error) in
                            if error != nil {
                                print("Error deleting profile pic: \(error!)")
                            }
                        })
                    } else {
                        print("Failed to get profPicStorageRef")
                    }
                })
                let imageName = NSUUID().uuidString
                DataService.instance.profPicStorageRef.child(imageName).putData(imageData, metadata: StorageMetadata(), completion: { (metadata, error) in
                    if let downloadURL = metadata?.downloadURL()?.absoluteString {
                        DataService.instance.profilesRef.child(self.currentUser).updateChildValues(["profPicUrl":downloadURL])
                        DataService.instance.saveLocalProfilePic(imageData: imageData)
                        print("Successfully changed image")
                    } else {
                        print("Failed to get downloadUrl")
                    }
                })
                
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
