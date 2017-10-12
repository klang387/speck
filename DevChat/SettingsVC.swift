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
    @IBOutlet weak var topBarBottomConstraint: NSLayoutConstraint!
    
    var changeNameVC: ChangeNameVC?
    var changePasswordVC: ChangePasswordVC?
    var friendsVC: FriendsVC?
    var guideVC: GuideVC?
    var image: UIImage?
    var imagePicker: CustomImagePicker!
    var editLayer: CAShapeLayer!
    var label: UILabel!
    var currentView: String!
    var newViewStartFrame: CGRect!
    var friendsObserver: UInt!
    var requestCount: Int!
    var currentUser: String!
    var constraintLeading: NSLayoutConstraint?
    var constraintTrailing: NSLayoutConstraint?
    var constraintLeadingLandscape: NSLayoutConstraint?
    var textFields: [UITextField]!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentUser = AuthService.instance.currentUser
        textFields = []
        profilePic.image = image
        profilePic.layer.masksToBounds = true
        friendsBadge.layer.cornerRadius = friendsBadge.layer.frame.width / 2
        friendsBadge.layer.masksToBounds = true
        friendsBadge.text = String(requestCount)
        if requestCount > 0 {
            friendsBadge.isHidden = false
        }
        imagePicker = CustomImagePicker()
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
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
        textFields = [changeNameVC!.newUsername]
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
            textFields = [changePasswordVC!.oldPassword, changePasswordVC!.newPassword, changePasswordVC!.repeatNewPassword]
            animateButtonsIn(controller: changePasswordVC!)
        } else {
            let alert = ErrorAlert(title: "Facebook Login", message: "Looks like you're logged in via Facebook, and there's no password to change.", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func friendsPressed(_ sender: Any) {
        self.currentView = "friends"
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: nil, completion: { _ in
            for field in self.textFields {
                if field.isFirstResponder {
                    self.view.animateViewMoving(textField: field, constraint: self.topBarBottomConstraint)
                    return
                }
            }
        })
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
        currentView = "settings"
        view.endEditing(true)
        textFields = []
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
        if let imageVC = NSClassFromString("PUUIImageViewController") {
            if viewController.isKind(of: imageVC) || viewController.navigationItem.title == "Choose Photo" {
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
        let viewWidth = viewController.view.frame.width
        let viewHeight = viewController.view.frame.height - viewController.topLayoutGuide.length - viewController.bottomLayoutGuide.length
        var position = viewController.topLayoutGuide.length + viewHeight / 2 - viewWidth / 2
        if viewController.topLayoutGuide.length > 0 {
            position -= 4
        }
        
        let emptyShapePath = UIBezierPath(ovalIn: CGRect(x: 2, y: position + 2, width: viewWidth - 4, height: viewWidth - 4))
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
        
        label = UILabel(frame: CGRect(x: 0, y: 30, width: viewWidth, height: 50))
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
    
    func changePasswordSavePressed() {
        view.animateViewMoving(textField: nil, constraint: self.topBarBottomConstraint)
    }
    
    func changeNameDismiss() {
        animateButtonsOut(controller: changeNameVC!)
    }
    
    func changeNameSavePressed() {
        view.animateViewMoving(textField: nil, constraint: self.topBarBottomConstraint)
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
        view.animateViewMoving(textField: textField, constraint: topBarBottomConstraint)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.animateViewMoving(textField: nil, constraint: self.topBarBottomConstraint)
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if changeNameVC != nil {
            changeNameVC?.savePressed(self)
            view.animateViewMoving(textField: nil, constraint: self.topBarBottomConstraint)
            view.endEditing(true)
        } else if changePasswordVC != nil {
            switch textField {
            case changePasswordVC!.oldPassword:
                changePasswordVC?.newPassword.becomeFirstResponder()
            case changePasswordVC!.newPassword:
                changePasswordVC?.repeatNewPassword.becomeFirstResponder()
            case changePasswordVC!.repeatNewPassword:
                changePasswordVC?.savePressed(self)
                view.animateViewMoving(textField: nil, constraint: self.topBarBottomConstraint)
                view.endEditing(true)
            default: break
            }
        }
        return true
    }
    
}
