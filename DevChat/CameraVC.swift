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
    
    @IBOutlet weak var captureBtn: SwiftyCamButton!
    @IBOutlet weak var switchCameraBtn: UIButton!
    @IBOutlet weak var settingsBtn: UIButton!
    @IBOutlet weak var flashBtn: UIButton!
    @IBOutlet weak var recFrame: UIImageView!
    @IBOutlet weak var inboxFrame: UIImageView!
    @IBOutlet weak var switchCameraFrame: UIImageView!
    @IBOutlet weak var topFrame: UIImageView!

    
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
            }
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
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let user = Auth.auth().currentUser?.uid {
            print(user)
            self.currentUser = user
            DataService.instance.profilesRef.child(currentUser).observeSingleEvent(of: .value, with: { (snapshot) in
                if let profile = snapshot.value as? [String:Any] {
                    if let profPicUrl = profile["profPicUrl"] as? String {
                        URLSession.shared.dataTask(with: NSURL(string: profPicUrl)! as URL, completionHandler: { (data, response, error) -> Void in
                            if error != nil {
                                print(error!)
                                return
                            }
                            DispatchQueue.main.async(execute: { () -> Void in
                                self.profilePic = UIImage(data: data!)
                                self.settingsBtn.setImage(self.profilePic, for: .normal)
                            })
                        }).resume()
                    }
                }
            })
        } else {
            performSegue(withIdentifier: "toLoginVC", sender: nil)
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

