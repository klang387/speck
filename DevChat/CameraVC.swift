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
import CoreGraphics

class CameraVC: SwiftyCamViewController, SwiftyCamViewControllerDelegate {
    
    var currentUser = ""
    var profilePic: UIImage?
    
    var tempVidUrl: URL?
    var tempPhoto: UIImage?
    
    var dataType: String = ""
    
    var blurView: UIVisualEffectView!
    var blurStatus = false
    
    @IBOutlet weak var captureBtn: SwiftyCamButton!
    @IBOutlet weak var switchCameraBtn: UIButton!
    @IBOutlet weak var settingsBtn: RoundedButton!
    @IBOutlet weak var flashBtn: UIButton!
    @IBOutlet weak var blurMaskView: UIView!
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
            flashBtn.setImage(UIImage(named: "FlashBtnOff"), for: .normal)
        } else {
            flashEnabled = true
            flashBtn.setImage(UIImage(named: "FlashBtnOn"), for: .normal)
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
        
        let blur = UIBlurEffect(style: .light)
        blurView = UIVisualEffectView(effect: blur)
        blurView.frame = self.view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.insertSubview(blurView, belowSubview: blurMaskView)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let currentUser = Auth.auth().currentUser?.uid {
            self.currentUser = currentUser
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

        if !blurStatus {
            
            let maskView = UIImage(view: blurMaskView)
            let maskImage = maskView.cgImage?.copy(maskingColorComponents: [222,255,222,255,222,255,222,255])
            blurMaskView.backgroundColor = UIColor.clear
            
            recFrame.image = UIImage(named: "RecFrame")
            inboxFrame.image = UIImage(named: "InboxFrame")
            switchCameraFrame.image = UIImage(named: "SwitchCameraFrame")
            topFrame.image = UIImage(named: "TopFrame")
            
            let imageView = UIImageView(image: UIImage(cgImage: maskImage!))
            imageView.frame = view.frame
            blurView.mask = imageView
            
            blurStatus = true
            
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

