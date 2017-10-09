//
//  SettingsVC.swift
//  Speck
//
//  Created by Kevin Langelier on 8/17/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseAuth

class SettingsVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, ChangePasswordDelegate, ChangeNameDelegate, FriendsDelegate {

    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var buttonsView: UIView!
    @IBOutlet weak var friendsBadge: UILabel!
    @IBOutlet weak var topBar: UIImageView!
    @IBOutlet weak var buttonsStack: UIStackView!
    @IBOutlet weak var buttonsLeading: NSLayoutConstraint!
    @IBOutlet weak var buttonsTrailing: NSLayoutConstraint!
    @IBOutlet weak var buttonsLeadingLandscape: NSLayoutConstraint!
    @IBOutlet weak var buttonsTrailingLandscape: NSLayoutConstraint!
    
    var changeNameVC: ChangeNameVC?
    var changePasswordVC: ChangePasswordVC?
    var friendsVC: FriendsVC?
    var guideVC: GuideVC?
    var image: UIImage?
    var imagePicker: UIImagePickerController!
    var editLayer: CAShapeLayer!
    var label: UILabel!
    var currentView: String!
    var newViewStartFrame: CGRect!
    var friendsObserver: UInt!
    var requestCount: Int!
    var currentUser: String!
    var tapGesture: UITapGestureRecognizer!
    var constraintLeading: NSLayoutConstraint?
    var constraintTrailing: NSLayoutConstraint?
    var constraintLeadingLandscape: NSLayoutConstraint?

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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        profilePic.layer.cornerRadius = profilePic.frame.width / 2
        newViewStartFrame = CGRect(x: view.frame.width, y: 0, width: view.frame.width, height: view.frame.height)
    }
    
    @IBAction func changePhotoPressed(_ sender: Any) {
        AppDelegate.AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func changeNamePressed(_ sender: Any) {
        currentView = "name"
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        changeNameVC = (storyboard.instantiateViewController(withIdentifier: "ChangeNameVC") as! ChangeNameVC)
        addChildViewController(changeNameVC!)
        view.addSubview(changeNameVC!.view!)
        changeNameVC?.delegate = self
        changeNameVC?.newUsername.delegate = self
        animateButtonsIn(controller: changeNameVC!)
    }
    
    @IBAction func changePasswordPressed(_ sender: Any) {
        if UserDefaults.standard.bool(forKey: "facebookLogin") != true {
            currentView = "password"
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            changePasswordVC = (storyboard.instantiateViewController(withIdentifier: "ChangePasswordVC") as! ChangePasswordVC)
            addChildViewController(changePasswordVC!)
            view.addSubview(changePasswordVC!.view!)
            changePasswordVC?.delegate = self
            changePasswordVC?.oldPassword.delegate = self
            changePasswordVC?.newPassword.delegate = self
            changePasswordVC?.repeatNewPassword.delegate = self
            animateButtonsIn(controller: changePasswordVC!)
        } else {
            let alert = ErrorAlert(title: "Facebook Login", message: "Looks like you're logged in via Facebook, and there's no password to change.", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func friendsPressed(_ sender: Any) {
        self.currentView = "friends"
        tapGesture.isEnabled = false
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        friendsVC = storyboard.instantiateViewController(withIdentifier: "FriendsVC") as? FriendsVC
        addChildViewController(friendsVC!)
        friendsVC?.view.frame = newViewStartFrame
        view.insertSubview(friendsVC!.view, belowSubview: topBar)
        friendsVC?.delegate = self
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.3, animations: {
            self.friendsVC?.view.frame = self.view.frame
            self.view.layoutIfNeeded()
        })
    }

    @IBAction func backPressed(_ sender: Any) {
        switch currentView {
        case "settings":
            AppDelegate.AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
            self.dismiss(animated: true, completion: nil)
        case "name":
            currentView = "settings"
            changeNameDismiss()
        case "password":
            currentView = "settings"
            changePasswordDismiss()
        case "friends":
            currentView = "settings"
            friendsDismiss()
        default: break
        }
    }
    
    @IBAction func signOutPressed(_ sender: Any) {
        do {
            DataService.instance.removeToken()
            try Auth.auth().signOut()
            weak var cameraVC = self.presentingViewController
            AppDelegate.AppUtility.lockOrientation(.allButUpsideDown)
            UserDefaults.standard.removeObject(forKey: "facebookLogin")
            self.dismiss(animated: true) {
                cameraVC?.performSegue(withIdentifier: "toLoginVC", sender: nil)
            }
        } catch {
            let alert = ErrorAlert(title: "Uh Oh", message: "Unable to sign out.  Please check your internet connection and try again!", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
        }
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        if constraintLeading != nil {
            let compact = newCollection.verticalSizeClass == .compact ? true : false
            constraintLeading?.isActive = !compact
            constraintLeadingLandscape?.isActive = compact
        }
    }
    
    func animateButtonsIn(controller: UIViewController) {
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.topAnchor.constraint(equalTo: self.buttonsView.topAnchor, constant: 0).isActive = true
        controller.view.bottomAnchor.constraint(equalTo: self.buttonsView.bottomAnchor, constant: 0).isActive = true
        constraintLeading = controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: view.frame.width)
        constraintLeadingLandscape = controller.view.leadingAnchor.constraint(equalTo: profilePic.trailingAnchor, constant: view.frame.width)
        constraintTrailing = controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: view.frame.width)
        let compact = view.traitCollection.verticalSizeClass == .compact ? true : false
        constraintLeading?.isActive = !compact
        constraintLeadingLandscape?.isActive = compact
        constraintTrailing?.isActive = true
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.2, animations: {
            let height = self.view.frame.height
            let width = self.view.frame.width
            let greaterDimension = height > width ? height : width
            let smallerDimension = height > width ? width : height
            self.buttonsLeading.constant += smallerDimension
            self.buttonsTrailing.constant -= smallerDimension
            self.buttonsLeadingLandscape.constant += greaterDimension
            self.buttonsTrailingLandscape.constant -= greaterDimension
            self.view.layoutIfNeeded()
        }) { (finished) in
            UIView.animate(withDuration: 0.2, animations: {
                self.constraintLeading?.constant = 0
                self.constraintLeadingLandscape?.constant = 40
                self.constraintTrailing?.constant = 0
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func animateButtonsOut(controller: UIViewController) {
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.2, animations: {
            self.constraintLeading?.constant = self.view.frame.width
            self.constraintLeadingLandscape?.constant = self.view.frame.width
            self.constraintTrailing?.constant = self.view.frame.width
            self.buttonsLeading.constant = self.view.frame.width
            self.buttonsLeadingLandscape.constant = self.view.frame.width
            self.view.layoutIfNeeded()
        }) { (finished) in
            self.constraintLeading = nil
            self.constraintLeadingLandscape = nil
            self.constraintTrailing = nil
            self.changeNameVC?.view.removeFromSuperview()
            self.changeNameVC?.removeFromParentViewController()
            self.changeNameVC = nil
            self.changePasswordVC?.view.removeFromSuperview()
            self.changePasswordVC?.removeFromParentViewController()
            self.changePasswordVC = nil
            UIView.animate(withDuration: 0.2, animations: {
                self.buttonsLeading.constant = 0
                self.buttonsTrailing.constant = 0
                self.buttonsLeadingLandscape.constant = 40
                self.buttonsTrailingLandscape.constant = 0
                self.view.layoutIfNeeded()
            }) { (finished) in
                
            }
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let imageVC = NSClassFromString("PUUIImageViewController")
        {
            if viewController.isKind(of: imageVC) {
                addRoundedEditLayer(to: viewController, forCamera: false)
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            profilePic.image = image
            if let imageData = UIImageJPEGRepresentation(image, 0.2) {
                let imageName = NSUUID().uuidString
                DataService.instance.usersRef.child(currentUser).child("profPicStorageRef").observeSingleEvent(of: .value, with: { (snapshot) in
                    DataService.instance.usersRef.child(self.currentUser).child("profPicStorageRef").setValue(imageName)
                    if let profPicStorageRef = snapshot.value as? String {
                        DataService.instance.profPicStorageRef.child(profPicStorageRef).delete()
                    }
                })
                DataService.instance.profPicStorageRef.child(imageName).putData(imageData, metadata: StorageMetadata(), completion: { (metadata, error) in
                    if let downloadURL = metadata?.downloadURL()?.absoluteString {
                        DataService.instance.profilesRef.child(self.currentUser).updateChildValues(["profPicUrl":downloadURL])
                        DataService.instance.saveLocalProfilePic(imageData: imageData)
                    } else {
                        let alert = ErrorAlert(title: "Uh Oh", message: "Couldn't finish changing profile picture.  Please check your internet connection and try again!", preferredStyle: .alert)
                        self.present(alert, animated: true, completion: nil)
                    }
                })
            } else {
                let alert = ErrorAlert(title: "Uh Oh", message: "Couldn't finish changing profile picture.  Please check your internet connection and try again!", preferredStyle: .alert)
                present(alert, animated: true, completion: nil)
            }
        } else {
            let alert = ErrorAlert(title: "Uh Oh", message: "Invalid image selected.  Please try again.", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
        }
        imagePicker.dismiss(animated: true, completion: nil)
        AppDelegate.AppUtility.lockOrientation(.allButUpsideDown)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
        AppDelegate.AppUtility.lockOrientation(.allButUpsideDown)
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
    
    func changePasswordDismiss() {
        animateButtonsOut(controller: changePasswordVC!)
    }
    
    func changeNameDismiss() {
        animateButtonsOut(controller: changeNameVC!)
    }
    
    func friendsDismiss() {
        friendsVC?.searchBar.endEditing(true)
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.2, animations: {
            self.friendsVC?.view.frame.origin.x += self.view.frame.width
            self.view.layoutIfNeeded()
        }) { (finished) in
            self.friendsVC?.view.removeFromSuperview()
            self.friendsVC?.removeFromParentViewController()
            self.friendsVC = nil
        }
        tapGesture.isEnabled = true
    }
    
    func addSearchGuide() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guideVC = storyboard.instantiateViewController(withIdentifier: "GuideVC") as? GuideVC
        addChildViewController(guideVC!)
        guideVC?.view.frame = view.frame
        view.addSubview(guideVC!.view)
        guideVC?.dismissBtn.addTarget(self, action: #selector(removeGuide), for: .touchUpInside)
    }
    
    @objc func removeGuide() {
        guideVC?.view.removeFromSuperview()
        guideVC?.removeFromParentViewController()
        guideVC = nil
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        view.animateViewMoving(textField: textField, view: view)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        view.animateViewMoving(textField: nil, view: view)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }

    
}
