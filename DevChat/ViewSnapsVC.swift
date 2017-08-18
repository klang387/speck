//
//  ViewSnapsVC.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/12/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit
import AVFoundation

class ViewSnapsVC: UIViewController {

    @IBOutlet weak var closeBtn: UIButton!
    
    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!
    
    var imageView = UIImageView()
    
    @IBAction func closePressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var photoUrl: String?
    var videoUrl: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        avPlayerLayer.frame = view.frame
        view.layer.insertSublayer(avPlayerLayer, below: closeBtn.layer)
        
        imageView.frame = view.frame
        view.insertSubview(imageView, belowSubview: closeBtn)
        
        if photoUrl != nil {
            imageView.imageFromServerURL(urlString: photoUrl!)
        } else if videoUrl != nil {
            let url = URL(string: videoUrl!)
            let playerItem = AVPlayerItem(url: url!)
            avPlayerLayer.player?.replaceCurrentItem(with: playerItem)
            avPlayerLayer.player?.play()
        }
    }

}
