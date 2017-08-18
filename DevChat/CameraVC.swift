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
    
    var tempVidUrl: URL?
    var tempPhoto: UIImage?
    
    var dataType: String = ""
    
    @IBOutlet weak var captureBtn: SwiftyCamButton!
    @IBOutlet weak var switchCameraBtn: UIButton!
    
    @IBAction func switchCameraBtnPressed(_ sender: Any) {
        switchCamera()
    }
    
    @IBAction func inboxBtnPressed(_ sender: Any) {
        performSegue(withIdentifier: "toInboxVC", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
    
    @IBAction func settingsPressed(_ sender: Any) {
        performSegue(withIdentifier: "toSettingsVC", sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraDelegate = self
        captureBtn.delegate = self
        maximumVideoDuration = 10.0
        
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

