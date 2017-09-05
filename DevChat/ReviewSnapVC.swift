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
import QuartzCore

class ReviewSnapVC: UIViewController, SendSnapDelegate {

    @IBOutlet weak var bottomBar: UIImageView!
    @IBOutlet weak var topBar: UIImageView!
    @IBOutlet weak var sendBtn: UIButton!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet var tapRecognizer: UITapGestureRecognizer!
    
    let snapViewer = SnapViewer()
    
    var tempVidUrl: URL?
    var tempPhoto: UIImage?
    var tempPhotoData: Data?
    
    var dataType: String = ""
    
    var currentView = "preview"
    var sendSnapVC: SendSnapVC?
    
    var navBarVisible = true
    var alphaTarget: CGFloat = 1
    var animatable = true
    
    var newViewStartFrame: CGRect!
    
    lazy var slideInTransitioningDelegate = SlideInPresentationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        newViewStartFrame = CGRect(origin: CGPoint(x: view.frame.origin.x + view.frame.width, y: view.frame.origin.y), size: view.frame.size)
        
        if dataType == "video" {
            snapViewer.playerItem = AVPlayerItem(url: tempVidUrl!)
        } else if dataType == "photo" {
            snapViewer.imageView.image = tempPhoto
            tempPhotoData = UIImageJPEGRepresentation(tempPhoto!, 0.2)
        }
        
        addChildViewController(snapViewer)
        view.insertSubview(snapViewer.view, belowSubview: topBar)
        
    }
    
    @IBAction func tapGesture(_ sender: Any) {
        if animatable {
            animatable = false
            alphaTarget = abs(alphaTarget - 1)
            UIView.animate(withDuration: 0.2, animations: {
                self.topBar.alpha = self.alphaTarget
                self.backBtn.alpha = self.alphaTarget
                self.bottomBar.alpha = self.alphaTarget
                self.sendBtn.alpha = self.alphaTarget
            }) { (finished) in
                self.animatable = true
            }
        }
    }
    
    @IBAction func sendToUsersBtnPressed(_ sender: Any) {
        if currentView == "preview" {
            tapRecognizer.isEnabled = false
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            sendSnapVC = storyboard.instantiateViewController(withIdentifier: "SendSnapVC") as? SendSnapVC
            sendSnapVC!.delegate = self
            
            if dataType == "video" {
                sendSnapVC!.tempVidUrl = tempVidUrl
            } else if dataType == "photo" {
                sendSnapVC!.tempPhotoData = tempPhotoData
            }
            
            addChildViewController(sendSnapVC!)
            sendSnapVC!.view.frame = newViewStartFrame
            view.insertSubview(sendSnapVC!.view, belowSubview: bottomBar)
            UIView.animate(withDuration: 0.3, animations: { 
                self.sendSnapVC!.view.frame = self.view.frame
            }, completion: { (finished) in
                if finished {
                    self.bottomBar.image = UIImage(named: "BottomSendWhite")
                    self.currentView = "send"
                }
            })
        } else if currentView == "send" {
            if sendSnapVC != nil {
                DataService.instance.uploadMedia(tempVidUrl: sendSnapVC!.tempVidUrl, tempPhotoData: sendSnapVC!.tempPhotoData, caption: nil, recipients: sendSnapVC!.selectedUsers, completion: {
                    removeSendSnapVC()
                })
            }
        }
        
    }
    
    @IBAction func closePreviewBtnPressed(_ sender: Any) {
        if currentView == "preview" {
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
        } else if currentView == "send" {
            removeSendSnapVC()
        }
    }
    
    func removeSendSnapVC() {
        bottomBar.image = UIImage(named: "BottomSendAlpha")
        sendBtn.imageView?.image = UIImage(named: "SendBtnGreen")
        UIView.animate(withDuration: 0.3, animations: {
            self.sendSnapVC!.view.frame = self.newViewStartFrame
        }, completion: { (finished) in
            if finished {
                self.sendSnapVC!.removeFromParentViewController()
                self.currentView = "preview"
                self.tapRecognizer.isEnabled = true
            }
        })
    }
    
    func rowsAreSelected(selected: Bool) {
        print("rowsAreSelected executed")
        if selected {
            bottomBar.image = UIImage(named: "BottomSendGreen")
            sendBtn.imageView?.image = UIImage(named: "SendBtnWhite")
        } else {
            bottomBar.image = UIImage(named: "BottomSendWhite")
            sendBtn.imageView?.image = UIImage(named: "SendBtnGreen")
        }
    }

}
