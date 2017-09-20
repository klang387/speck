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

class ReviewSnapVC: UIViewController, SendSnapDelegate {

    @IBOutlet weak var bottomBar: UIImageView!
    @IBOutlet weak var bottomBarTab: UIImageView!
    @IBOutlet weak var topBar: UIImageView!
    @IBOutlet weak var topBarTab: UIImageView!
    @IBOutlet weak var sendBtn: UIButton!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var captionBtn: UIButton!
    @IBOutlet var tapRecognizer: UITapGestureRecognizer!
    
    var snapViewer: SnapViewer!
    
    var tempVidUrl: URL?
    var tempPhoto: UIImage?
    var tempPhotoData: Data?
    
    var dataType = ""
    
    var currentView = "preview"
    var sendSnapVC: SendSnapVC?
    
    var navBarVisible = true
    var btnAlphaTarget: CGFloat = 1
    var barAlphaTarget: CGFloat = 1
    var animatable = true
    
    var newViewStartFrame: CGRect!
    
    var orientation: UIInterfaceOrientationMask?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        snapViewer = SnapViewer()
        addChildViewController(snapViewer)
        view.insertSubview(snapViewer.view, belowSubview: captionBtn)
        
        bottomBarTab.transform = CGAffineTransform(scaleX: -1, y: -1)
        
        newViewStartFrame = CGRect(origin: CGPoint(x: view.frame.origin.x + view.frame.width, y: view.frame.origin.y), size: view.frame.size)
        
        if dataType == "video" {
            snapViewer.playerItem = AVPlayerItem(url: tempVidUrl!)
        } else if dataType == "photo" {
            snapViewer.imageView.image = tempPhoto
            tempPhotoData = UIImageJPEGRepresentation(tempPhoto!, 0.2)
        }
    }
    
    @IBAction func tapGesture(_ sender: Any) {
        if animatable {
            animatable = false
            btnAlphaTarget = abs(btnAlphaTarget - 1)
            barAlphaTarget = abs(barAlphaTarget - 1)
            UIView.animate(withDuration: 0.2, animations: {
                self.topBar.alpha = self.barAlphaTarget
                self.topBarTab.alpha = self.barAlphaTarget
                self.backBtn.alpha = self.btnAlphaTarget
                self.bottomBar.alpha = self.barAlphaTarget
                self.bottomBarTab.alpha = self.barAlphaTarget
                self.sendBtn.alpha = self.btnAlphaTarget
                self.captionBtn.alpha = self.btnAlphaTarget
            }) { (finished) in
                self.animatable = true
            }
        }
    }
    
    @IBAction func captionPressed(_ sender: Any) {
        snapViewer.addCaption(editingEnabled: true)
    }
    
    @IBAction func sendToUsersBtnPressed(_ sender: Any) {
        if currentView == "preview" {
            AppDelegate.AppUtility.lockOrientation(.allButUpsideDown)
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
            bottomBar.image = UIImage(named: "BarGrey")
            bottomBarTab.image = UIImage(named: "TabGrey")
            sendBtn.setImage(UIImage(named: "SendBtnWhite"), for: .normal)
            UIView.animate(withDuration: 0.3, animations: {
                self.sendSnapVC!.view.frame = self.view.frame
                self.topBar.alpha = 1
                self.bottomBar.alpha = 1
            }, completion: { (finished) in
                if finished {
                    self.currentView = "send"
                }
            })
        } else if currentView == "send" && sendSnapVC != nil {
            if let count = sendSnapVC?.selectedUsers.count {
                guard count > 0 else { return }
                var caption: [String:Any]?
                if let text = snapViewer.captionField?.text, let position = snapViewer.captionField?.center.y {
                    caption = ["text":text, "yPos":position]
                }
                DataService.instance.uploadMedia(tempVidUrl: sendSnapVC!.tempVidUrl, tempPhotoData: sendSnapVC!.tempPhotoData, caption: caption, recipients: sendSnapVC!.selectedUsers, completion: {
                    removeSendSnapVC()
                })
            }
        }
    }
    
    @IBAction func closePreviewBtnPressed(_ sender: Any) {
        if currentView == "preview" {
            snapViewer.captionField?.endEditing(true)
            if dataType == "video" {
                let fileManager = FileManager.default
                do {
                    try fileManager.removeItem(at: tempVidUrl!)
                    print("Successfully deleted temp video")
                } catch {
                    print("Could not delete temp video: \(error)")
                }
            }
            AppDelegate.AppUtility.lockOrientation(.portrait)
            self.dismiss(animated: true, completion: nil)
        } else if currentView == "send" {
            sendSnapVC?.searchBar.endEditing(true)
            removeSendSnapVC()
        }
    }
    
    func removeSendSnapVC() {
        
        var value = UIInterfaceOrientation.portrait
        switch orientation! {
        case UIInterfaceOrientationMask.landscapeLeft:
            value = UIInterfaceOrientation.landscapeLeft
        case UIInterfaceOrientationMask.landscapeRight:
            value = UIInterfaceOrientation.landscapeRight
        default:
            break
        }
        AppDelegate.AppUtility.lockOrientation(orientation!, andRotateTo: value)
        bottomBar.image = UIImage(named: "BarGreen")
        bottomBarTab.image = UIImage(named: "TabGreen")
        sendBtn.setImage(UIImage(named: "SendBtnDark"), for: .normal)
        UIView.animate(withDuration: 0.3, animations: {
            self.sendSnapVC!.view.frame = self.newViewStartFrame
            self.bottomBar.alpha = 1
            self.topBar.alpha = 1
        }, completion: { (finished) in
            if finished {
                self.sendSnapVC?.view.removeFromSuperview()
                self.sendSnapVC?.removeFromParentViewController()
                self.sendSnapVC = nil
                self.currentView = "preview"
                self.tapRecognizer.isEnabled = true
            }
        })
    }
    
    func rowsAreSelected(selected: Bool) {
        if selected {
            bottomBar.image = UIImage(named: "BarGreen")
            bottomBarTab.image = UIImage(named: "TabGreen")
            sendBtn.setImage(UIImage(named: "SendBtnDark"), for: .normal)
        } else {
            bottomBar.image = UIImage(named: "BarGrey")
            bottomBarTab.image = UIImage(named: "TabGrey")
            sendBtn.setImage(UIImage(named: "SendBtnWhite"), for: .normal)
        }
    }

}
