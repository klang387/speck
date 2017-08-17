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
    
    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!
    
    var imageView = UIImageView()
    
    var tempVidUrl: URL?
    var tempPhoto: UIImage?
    
    var dataType: String = ""
    
    @IBOutlet weak var captureBtn: SwiftyCamButton!
    @IBOutlet weak var switchCameraBtn: UIButton!
    @IBOutlet weak var sendToUsersBtn: UIButton!
    @IBOutlet weak var closePreviewBtn: UIButton!
    
    @IBAction func switchCameraBtnPressed(_ sender: Any) {
        switchCamera()
    }
    
    @IBAction func sendToUsersBtnPressed(_ sender: Any) {
        if dataType == "video" {
            performSegue(withIdentifier: "toUsersVC", sender: tempVidUrl)
        } else if dataType == "photo" {
            if let tempPhotoData = UIImageJPEGRepresentation(tempPhoto!, 0.8) {
                performSegue(withIdentifier: "toUsersVC", sender: tempPhotoData)
            }
        }
    }
    
    @IBAction func inboxBtnPressed(_ sender: Any) {
        performSegue(withIdentifier: "toInboxVC", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let usersVC = segue.destination as? UsersVC {
            if dataType == "video" {
                usersVC.tempVidUrl = sender as? URL
            } else if dataType == "photo" {
                usersVC.tempPhotoData = sender as? Data
            }
        }
    }
    
    @IBAction func signOutPressed(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            performSegue(withIdentifier: "toLoginVC", sender: nil)
        } catch {
            print("Sign out failed")
        }
    }
    
    @IBAction func closePreviewBtnPressed(_ sender: Any) {
        if dataType == "video" {
            let fileManager = FileManager.default
            do {
                try fileManager.removeItem(at: tempVidUrl!)
                print("Successfully deleted temp video")
            } catch {
                print("Could not delete temp video: \(error)")
            }
        }
        
        avPlayerLayer.isHidden = true
        sendToUsersBtn.isEnabled = false
        sendToUsersBtn.alpha = 0.3
        closePreviewBtn.isHidden = true
        closePreviewBtn.isEnabled = false
        imageView.isHidden = true
        imageView.image = nil
        tempVidUrl = nil
        tempPhoto = nil
        dataType = ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraDelegate = self
        captureBtn.delegate = self
        maximumVideoDuration = 10.0
        
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        avPlayerLayer.frame = view.frame
        view.layer.insertSublayer(avPlayerLayer, below: captureBtn.layer)
        
        imageView.frame = view.frame
        view.insertSubview(imageView, belowSubview: captureBtn)
        
        print("Current User: \(Auth.auth().currentUser)")
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        guard Auth.auth().currentUser != nil else {
            performSegue(withIdentifier: "toLoginVC", sender: nil)
            return
        }
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
        print("Took a photo")
        
        tempPhoto = photo
        imageView.image = photo
        imageView.isHidden = false
        
        sendToUsersBtn.isEnabled = true
        sendToUsersBtn.alpha = 1
        
        closePreviewBtn.isEnabled = true
        closePreviewBtn.isHidden = false
        
        dataType = "photo"
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
        
        let playerItem = AVPlayerItem(url: url)
        avPlayer.replaceCurrentItem(with: playerItem)
        avPlayerLayer.isHidden = false
        avPlayer.play()
        
        sendToUsersBtn.isEnabled = true
        sendToUsersBtn.alpha = 1
        
        closePreviewBtn.isEnabled = true
        closePreviewBtn.isHidden = false
        
        dataType = "video"
        
    }
    

}

