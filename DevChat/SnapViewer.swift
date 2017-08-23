//
//  ViewSnapsVC.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/12/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit
import AVFoundation

class SnapViewer: UIViewController {
    
    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer?
    var playerItem: AVPlayerItem?
    
    var avQueuePlayer: AVQueuePlayer?
    var looper: AVPlayerLooper?
    
    var imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        avPlayerLayer?.frame = view.frame
        view.layer.addSublayer(avPlayerLayer!)
        
        if playerItem != nil {
            avQueuePlayer = AVQueuePlayer(playerItem: playerItem!)
            looper = AVPlayerLooper(player: avQueuePlayer!, templateItem: playerItem!)
        }
        
        avPlayerLayer?.player = avQueuePlayer
        
        imageView.frame = view.frame
        view.addSubview(imageView)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if playerItem != nil {
            avQueuePlayer?.play()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if playerItem != nil {
            avQueuePlayer?.pause()
        }
    }

    
}
