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
    var btnAlphaTarget: CGFloat = 1
    var barAlphaTarget: CGFloat = 0.25
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
        view.insertSubview(snapViewer.view, belowSubview: bottomBar)
        
    }
    
    @IBAction func tapGesture(_ sender: Any) {
        if animatable {
            animatable = false
            btnAlphaTarget = abs(btnAlphaTarget - 1)
            barAlphaTarget = abs(barAlphaTarget - 0.25)
            UIView.animate(withDuration: 0.2, animations: {
                self.topBar.alpha = self.barAlphaTarget
                self.backBtn.alpha = self.btnAlphaTarget
                self.bottomBar.alpha = self.barAlphaTarget
                self.sendBtn.alpha = self.btnAlphaTarget
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
                self.topBar.alpha = 1
                self.bottomBar.alpha = 1
            }, completion: { (finished) in
                if finished {
                    self.currentView = "send"
                    self.sendBtn.setImage(UIImage(named: "SendBtnGrey"), for: .normal)
                }
            })
        } else if currentView == "send" && sendSnapVC != nil {
            if let count = sendSnapVC?.selectedUsers.count {
                guard count > 0 else { return }
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
        bottomBar.image = UIImage(named: "BottomBarGrey")
        sendBtn.imageView?.image = UIImage(named: "SendBtnGreen")
        UIView.animate(withDuration: 0.3, animations: {
            self.sendSnapVC!.view.frame = self.newViewStartFrame
            self.bottomBar.alpha = 0.25
            self.topBar.alpha = 0.25
        }, completion: { (finished) in
            if finished {
                self.sendSnapVC!.removeFromParentViewController()
                self.currentView = "preview"
                self.tapRecognizer.isEnabled = true
            }
        })
    }
    
    func rowsAreSelected(selected: Bool) {
        if selected {
            bottomBar.image = UIImage(named: "BottomBarGreen")
            sendBtn.imageView?.image = UIImage(named: "SendBtnGreen")
        } else {
            bottomBar.image = UIImage(named: "BottomBarGrey")
            sendBtn.imageView?.image = UIImage(named: "SendBtnGrey")
        }
    }

}
