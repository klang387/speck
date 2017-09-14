//
//  CameraVC.swift
//  DevChat
//
//  Created by Kevin Langelier on 7/20/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit
import FirebaseAuth
import SwiftyCam
import AVFoundation
import AVKit

class CameraVC: SwiftyCamViewController, SwiftyCamViewControllerDelegate {
    
    var currentUser = ""
    var profilePic: UIImage?
    
    var tempVidUrl: URL?
    var tempPhoto: UIImage?
    
    var dataType: String = ""
    
    var inboxObserver: UInt!
    var friendsObserver: UInt!
    var friendRequests = 0
    
    @IBOutlet weak var captureBtn: SwiftyCamButton!
    @IBOutlet weak var switchCameraBtn: UIButton!
    @IBOutlet weak var settingsBtn: UIButton!
    @IBOutlet weak var flashBtn: UIButton!
    @IBOutlet weak var recFrame: UIImageView!
    @IBOutlet weak var inboxFrame: UIImageView!
    @IBOutlet weak var switchCameraFrame: UIImageView!
    @IBOutlet weak var topFrame: UIImageView!
    @IBOutlet weak var inboxBadge: UILabel!
    @IBOutlet weak var friendsBadge: UILabel!
    
    @IBAction func switchCameraBtnPressed(_ sender: Any) {
        switchCamera()
    }
    
    @IBAction func inboxBtnPressed(_ sender: Any) {
        performSegue(withIdentifier: "toInboxVC", sender: nil)
    }
    
    @IBAction func settingsPressed(_ sender: Any) {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraDelegate = self
        captureBtn.delegate = self
        maximumVideoDuration = 10.0
        flashEnabled = false
        flashBtn.imageView?.contentMode = .scaleAspectFit
        let settingsMask = UIImageView(image: UIImage(named: "SettingsBtnMask"))
        settingsMask.frame.size = settingsBtn.frame.size
        settingsBtn.mask = settingsMask
        inboxBadge.layer.cornerRadius = inboxBadge.layer.frame.width / 2
        inboxBadge.layer.masksToBounds = true
        friendsBadge.layer.cornerRadius = friendsBadge.layer.frame.width / 2
        friendsBadge.layer.masksToBounds = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let user = Auth.auth().currentUser?.uid {
            self.currentUser = user
            
            friendsObserver = DataService.instance.usersRef.child(currentUser).child("friendRequests").observe(.value, with: { (snapshot) in
                if let friendRequests = snapshot.value as? [String:Any] {
                    self.friendRequests = friendRequests.count
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
                            if let snaps = contents["snaps"] as? [String:Any] {
                                count += snaps.count
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
                                    print(error!)
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
            performSegue(withIdentifier: "toLoginVC", sender: nil)
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if currentUser != "" {
            DataService.instance.usersRef.child(currentUser).child("snapsReceived").removeObserver(withHandle: inboxObserver)
            DataService.instance.usersRef.child(currentUser).child("friendRequests").removeObserver(withHandle: friendsObserver)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toReviewSnapVC" {
            if let reviewSnapVC = segue.destination as? ReviewSnapVC {
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
                settingsVC.requestCount = friendRequests
            }
        }
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
        print("Took a photo")
        
        tempPhoto = photo
        dataType = "photo"
        performSegue(withIdentifier: "toReviewSnapVC", sender: tempPhoto)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("Started recording new video")
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("Finished recording")
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        print("Finished processing video")
        
        tempVidUrl = url        
        dataType = "video"
        performSegue(withIdentifier: "toReviewSnapVC", sender: tempVidUrl)
        
    }
    

}

