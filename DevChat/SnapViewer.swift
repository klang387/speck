//
//  ViewSnapsVC.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/12/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit
import AVFoundation

class SnapViewer: UIViewController, UITextFieldDelegate {
    
    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer?
    var playerItem: AVPlayerItem?
    
    var avQueuePlayer: AVQueuePlayer?
    var looper: AVPlayerLooper?
    
    var imageView = UIImageView()
    
    var index: Int?
    
    var captionField: UITextField?
    var lastLocation: CGPoint?
    var panRecognizer: UIPanGestureRecognizer?
    
    var timestampLbl: UILabel?
    
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
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        imageView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
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
    
    func addTimestamp() {
        timestampLbl = UILabel(frame: CGRect(x: 80, y: 80, width: view.frame.width - 80, height: 40))
        timestampLbl?.font = UIFont(name: "Avenir", size: 14)
        timestampLbl?.textColor = .white
        timestampLbl?.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        timestampLbl?.textAlignment = .center
        view.addSubview(timestampLbl!)
    }
    
    func addCaption(editingEnabled: Bool) {
        captionField = UITextField(frame: CGRect(x: 0, y: view.frame.height / 2 - 20, width: view.frame.width, height: 40))
        captionField?.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        captionField?.font = UIFont(name: "Avenir-Heavy", size: 18)
        captionField?.textColor = .white
        captionField?.textAlignment = .center
        captionField?.tintColor = .white
        view.addSubview(captionField!)
        if editingEnabled {
            captionField?.returnKeyType = .done
            captionField?.becomeFirstResponder()
            lastLocation = captionField?.center
            captionField?.delegate = self
            panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(detectPan))
            captionField?.gestureRecognizers = [panRecognizer!]
        } else {
            captionField?.isEnabled = false
        }
    }
    
    func detectPan(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        switch recognizer.state {
        case .changed:
            if let view = recognizer.view {
                view.center = CGPoint(x: view.center.x, y: (view.center.y + translation.y > 50 && view.center.y + translation.y < self.view.frame.height - 50) ? view.center.y + translation.y : view.center.y)
                }
            recognizer.setTranslation(CGPoint.zero, in: self.view)
        default:
            break
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
}
