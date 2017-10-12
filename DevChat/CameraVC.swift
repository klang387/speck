//
//  CameraVC.swift
//  Speck
//
//  Created by Kevin Langelier on 7/20/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import SwiftyCam
import UserNotifications

class CameraVC: SwiftyCamViewController, SwiftyCamViewControllerDelegate {
    
    var profilePic: UIImage?
    var tempVidUrl: URL?
    var tempPhoto: UIImage?
    var dataType: String = ""
    var inboxObserver: UInt!
    var friendsObserver: UInt!
    var friendRequestsCount = 0
    var recordingTimer: UILabel?
    var recordingCount: Int?
    var timer: Timer?
    var buttonsArray: [UIButton]!
    var originalRotation: CATransform3D?
    var orientation: UIInterfaceOrientationMask?
    var welcomeArray: [UIView]!
    
    @IBOutlet weak var captureBtn: SwiftyCamButton!
    @IBOutlet weak var switchCameraBtn: UIButton!
    @IBOutlet weak var settingsBtn: UIButton!
    @IBOutlet weak var flashBtn: UIButton!
    @IBOutlet weak var flashFrame: UIImageView!
    @IBOutlet weak var inboxBadge: UILabel!
    @IBOutlet weak var inboxBtn: UIButton!
    @IBOutlet weak var friendsBadge: UILabel!
    
    @IBOutlet weak var welcomeGuideBgView: UIView!
    @IBOutlet weak var welcomeDismissBtn: UIButton!
    @IBOutlet weak var guideCapture: UIImageView!
    @IBOutlet weak var guideSettings: UIImageView!
    @IBOutlet weak var guideInbox: UIImageView!
    @IBOutlet weak var guideSwitchCamera: UIImageView!
    @IBOutlet weak var guideFlash: UIImageView!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var continueLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        AppDelegate.AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
        orientation = checkOrientation()
        
        welcomeArray = [welcomeGuideBgView, welcomeDismissBtn, guideCapture, guideSettings, guideInbox, guideSwitchCamera, guideFlash, welcomeLabel, continueLabel]
        if UserDefaults.standard.integer(forKey: "firstCameraVC") == 1 {
            for item in welcomeArray {
                item.removeFromSuperview()
            }
        }
        
        buttonsArray = [switchCameraBtn, flashBtn, inboxBtn]
        shouldUseDeviceOrientation = true
        allowAutoRotate = true
        originalRotation = inboxBadge.layer.transform
        flashFrame.transform = CGAffineTransform(scaleX: -1, y: 1)
        cameraDelegate = self
        captureBtn.delegate = self
        maximumVideoDuration = 10.0
        flashEnabled = false
        flashBtn.imageView?.contentMode = .scaleAspectFit
        settingsBtn.layer.cornerRadius = settingsBtn.frame.width / 2
        settingsBtn.layer.masksToBounds = true
        settingsBtn.imageView?.contentMode = .scaleAspectFill
        inboxBadge.layer.cornerRadius = inboxBadge.layer.frame.width / 2
        inboxBadge.layer.masksToBounds = true
        friendsBadge.layer.cornerRadius = friendsBadge.layer.frame.width / 2
        friendsBadge.layer.masksToBounds = true
    }
   
    override func viewDidAppear(_ animated: Bool) {
        if AuthService.instance.currentUser != "" {
            super.viewDidAppear(animated)
            
            if #available(iOS 10.0, *) {
                let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                UNUserNotificationCenter.current().requestAuthorization(
                    options: authOptions,
                    completionHandler: {_, _ in })
            } else {
                let settings: UIUserNotificationSettings =
                    UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
                UIApplication.shared.registerUserNotificationSettings(settings)
            }
            
            let currentUser = AuthService.instance.currentUser
            
            NotificationCenter.default.addObserver(self, selector: #selector(deviceRotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
                        
            friendsObserver = DataService.instance.usersRef.child(currentUser).child("friendRequests").observe(.value, with: { (snapshot) in
                if let friendRequests = snapshot.value as? [String:Any] {
                    self.friendRequestsCount = friendRequests.count
                    self.friendsBadge.text = String(friendRequests.count)
                    self.friendsBadge.isHidden = false
                } else {
                    self.friendsBadge.isHidden = true
                }
            })
            
            inboxObserver = DataService.instance.usersRef.child(currentUser).child("snapsReceived").observe(.value, with: { (snapshot) in
                var count = 0
                if let snapsReceived = snapshot.value as? [String:Any] {
                    for (_,value) in snapsReceived {
                        if let contents = value as? [String:Any] {
                            if let _ = contents["snaps"] as? [String:Any] {
                                count += 1
                            }
                        }
                    }
                }
                if count > 0 {
                    self.inboxBadge.text = String(count)
                    self.inboxBadge.isHidden = false
                } else {
                    self.inboxBadge.isHidden = true
                }
            })
            
            if let image = DataService.instance.loadLocalProfilePic() {
                self.profilePic = image
                settingsBtn.setImage(image, for: .normal)
            } else {
                DataService.instance.profilesRef.child(currentUser).observeSingleEvent(of: .value, with: { (snapshot) in
                    if let profile = snapshot.value as? [String:Any] {
                        if let profPicUrl = profile["profPicUrl"] as? String {
                            URLSession.shared.dataTask(with: NSURL(string: profPicUrl)! as URL, completionHandler: { (data, response, error) -> Void in
                                if error != nil {
                                    return
                                }
                                DispatchQueue.main.async(execute: { () -> Void in
                                    if let imageData = data {
                                        DataService.instance.saveLocalProfilePic(imageData: imageData)
                                        self.profilePic = UIImage(data: imageData)
                                        self.settingsBtn.setImage(self.profilePic, for: .normal)
                                    }
                                })
                            }).resume()
                        }
                    }
                })
            }
        } else {
            AppDelegate.AppUtility.lockOrientation(.allButUpsideDown)
            performSegue(withIdentifier: "toLoginVC", sender: nil)
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if AuthService.instance.currentUser != "" {
            let currentUser = AuthService.instance.currentUser
            DataService.instance.usersRef.child(currentUser).child("snapsReceived").removeObserver(withHandle: inboxObserver)
            DataService.instance.usersRef.child(currentUser).child("friendRequests").removeObserver(withHandle: friendsObserver)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        }
    }
    
    @IBAction func welcomeDismissBtnPressed(_ sender: Any) {
        for item in welcomeArray {
            item.removeFromSuperview()
        }
        UserDefaults.standard.set(1, forKey: "firstCameraVC")
    }
    
    @IBAction func switchCameraBtnPressed(_ sender: Any) {
        switchCamera()
    }
    
    @IBAction func inboxBtnPressed(_ sender: Any) {
        AppDelegate.AppUtility.lockOrientation(.allButUpsideDown)
        performSegue(withIdentifier: "toInboxVC", sender: nil)
    }
    
    @IBAction func settingsPressed(_ sender: Any) {
        AppDelegate.AppUtility.lockOrientation(.allButUpsideDown)
        performSegue(withIdentifier: "toSettingsVC", sender: nil)
    }
    
    @IBAction func flashPressed(_ sender: Any) {
        if flashEnabled {
            flashEnabled = false
            flashBtn.setImage(UIImage(named: "FlashOff"), for: .normal)
        } else {
            flashEnabled = true
            flashBtn.setImage(UIImage(named: "FlashOn"), for: .normal)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toReviewSnapVC" {
            if let reviewSnapVC = segue.destination as? ReviewSnapVC {
                reviewSnapVC.orientation = orientation
                
                AppDelegate.AppUtility.lockOrientation(orientation!)
                if dataType == "video" {
                    reviewSnapVC.tempVidUrl = sender as? URL
                    reviewSnapVC.dataType = "video"
                } else if dataType == "photo" {
                    reviewSnapVC.tempPhoto = sender as? UIImage
                    reviewSnapVC.dataType = "photo"
                }
            }
        }
        
        if segue.identifier == "toSettingsVC" {
            if let settingsVC = segue.destination as? SettingsVC, let image = profilePic {
                settingsVC.image = image
                settingsVC.requestCount = friendRequestsCount
            }
        }
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
        tempPhoto = photo
        dataType = "photo"
        performSegue(withIdentifier: "toReviewSnapVC", sender: tempPhoto)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        let width: CGFloat = 180
        recordingTimer = UILabel(frame: CGRect(x: view.frame.width / 2 - width / 2, y: 50, width: width, height: 60))
        recordingTimer?.font = UIFont(name: "Avenir-Heavy", size: 50)
        recordingTimer?.textAlignment = .center
        recordingTimer?.textColor = .white
        recordingTimer?.alpha = 0.9
        recordingCount = Int(maximumVideoDuration)
        recordingTimer?.text = "10"
        view.addSubview(recordingTimer!)
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        recordingTimer?.removeFromSuperview()
        recordingTimer = nil
        timer?.invalidate()
        timer = nil
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        tempVidUrl = url
        dataType = "video"
        performSegue(withIdentifier: "toReviewSnapVC", sender: tempVidUrl)
        
    }
    
    @objc func updateTimer() {
        recordingCount = recordingCount! - 1
        if recordingCount == 9 {
            recordingTimer?.alpha = 0.1
        }
        recordingTimer?.alpha += 0.09
        recordingTimer?.text = "\(recordingCount!)"
    }
    
    func checkOrientation() -> UIInterfaceOrientationMask {
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .portrait
        }
    }
    
    @objc func deviceRotated() {
        var angle: CGFloat = 0
        orientation = checkOrientation()
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            angle = .pi * 0.5
        case .landscapeRight:
            angle = .pi * -0.5
        default:
            break
        }
        UIView.animate(withDuration: 0.15, animations: {
            for button in self.buttonsArray {
                button.imageView?.contentMode = .center
                button.imageView?.clipsToBounds = false
                button.imageView?.transform = CGAffineTransform(rotationAngle: angle)
            }
            self.inboxBadge.transform = CGAffineTransform(rotationAngle: angle)
            self.friendsBadge.transform = CGAffineTransform(rotationAngle: angle)
            self.settingsBtn.imageView?.transform = CGAffineTransform(rotationAngle: angle)
        }) { (finished) in
            
        }
    }
    
}

