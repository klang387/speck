//
//  ViewSnapsVC.swift
//  Speck
//
//  Created by Kevin Langelier on 8/12/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit
import AVFoundation

class SnapViewer: UIViewController, UITextFieldDelegate {
    
    var avPlayer: AVPlayer?
    var avPlayerLayer: AVPlayerLayer?
    var playerItem: AVPlayerItem?
    var avQueuePlayer: AVQueuePlayer?
    var looper: AVPlayerLooper?
    var imageView: UIImageView?
    var index: Int?
    var captionField: UITextField?
    var lastLocation: CGPoint?
    var panRecognizer: UIPanGestureRecognizer?
    var captionPosY: CGFloat?
    var timestampLbl: UILabel?
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        avPlayerLayer?.frame = view.frame
        imageView?.frame = view.frame
        guard let position = captionPosY else { return }
        captionField?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 40)
        captionField?.center.y = view.frame.height * position
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
    
    func addPhoto() {
        imageView = UIImageView()
        imageView?.contentMode = .scaleAspectFit
        imageView?.frame = view.frame
        view.addSubview(imageView!)
    }
    
    func addVideo() {
        avPlayer = AVPlayer()
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
        avPlayerLayer?.frame = view.frame
        view.layer.addSublayer(avPlayerLayer!)

        if playerItem != nil {
            avQueuePlayer = AVQueuePlayer(playerItem: playerItem!)
            looper = AVPlayerLooper(player: avQueuePlayer!, templateItem: playerItem!)
        }
                
        avPlayerLayer?.player = avQueuePlayer
    }
    
    func addTimestamp() {
        timestampLbl = UILabel()
        timestampLbl?.font = UIFont(name: "Avenir", size: 14)
        timestampLbl?.textColor = .white
        timestampLbl?.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        timestampLbl?.textAlignment = .center
        view.addSubview(timestampLbl!)
        timestampLbl?.translatesAutoresizingMaskIntoConstraints = false
        timestampLbl?.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        timestampLbl?.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
        timestampLbl?.heightAnchor.constraint(equalToConstant: 30).isActive = true
        timestampLbl?.widthAnchor.constraint(equalToConstant: 170).isActive = true
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
    
    @objc func detectPan(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        switch recognizer.state {
        case .changed:
            if let view = recognizer.view {
                view.center = CGPoint(x: view.center.x, y: (view.center.y + translation.y > 100 && view.center.y + translation.y < self.view.frame.height - 50) ? view.center.y + translation.y : view.center.y)
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
