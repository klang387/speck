//
//  ReviewSnapVC.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/17/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class ReviewSnapVC: UIViewController {

    @IBOutlet weak var closeBtn: UIButton!
    
    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!

    var imageView = UIImageView()
    
    var tempVidUrl: URL?
    var tempPhoto: UIImage?
    var tempPhotoData: Data?
    
    var dataType: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        avPlayerLayer.frame = view.frame
        view.layer.insertSublayer(avPlayerLayer, below: closeBtn.layer)
        
        imageView.frame = view.frame
        view.insertSubview(imageView, belowSubview: closeBtn)
        
        if dataType == "video" {
            let playerItem = AVPlayerItem(url: tempVidUrl!)
            avPlayerLayer.player?.replaceCurrentItem(with: playerItem)
            avPlayerLayer.player?.play()
        } else if dataType == "photo" {
            imageView.image = tempPhoto
            tempPhotoData = UIImageJPEGRepresentation(tempPhoto!, 0.2)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let sendSnapVC = segue.destination as? SendSnapVC {
            if dataType == "video" {
                sendSnapVC.tempVidUrl = sender as? URL
            } else if dataType == "photo" {
                sendSnapVC.tempPhotoData = sender as? Data
            }
        }
    }
    
    @IBAction func sendToUsersBtnPressed(_ sender: Any) {
        if dataType == "video" {
            performSegue(withIdentifier: "toSendSnapVC", sender: tempVidUrl)
        } else if dataType == "photo" {
            performSegue(withIdentifier: "toSendSnapVC", sender: tempPhotoData)
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
        self.dismiss(animated: true, completion: nil)
    }

}
