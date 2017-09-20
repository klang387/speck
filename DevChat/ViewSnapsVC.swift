//
//  ViewSnapsVC.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/12/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit
import AVFoundation

class ViewSnapsVC: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var previousBtn: UIButton!
    @IBOutlet var tapRecognizer: UITapGestureRecognizer!

    let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    var snapViewControllers = [SnapViewer]()
    var senderUid = String()
    
    var snaps = [String:Any]()
    var snapsArray = [[String:Any]]()
    var viewedSnaps = 0
    
    var animatable = true
    var btnAlphaTarget: CGFloat = 1
    var currentVC: SnapViewer?
    
    @IBAction func tapGesture(_ sender: Any) {
        if animatable {
            animatable = false
            btnAlphaTarget = abs(btnAlphaTarget - 1)
            if let viewer = self.pageVC.viewControllers?.first {
                currentVC = (viewer as! SnapViewer)
            }
            UIView.animate(withDuration: 0.2, animations: {
                self.closeBtn.alpha = self.btnAlphaTarget
                self.nextBtn.alpha = self.btnAlphaTarget
                self.previousBtn.alpha = self.btnAlphaTarget
                self.currentVC?.captionField?.alpha = self.btnAlphaTarget
                self.currentVC?.timestampLbl?.alpha = self.btnAlphaTarget
                
            }) { (finished) in
                self.animatable = true
            }
        }
    }
    
    @IBAction func closePressed(_ sender: Any) {
        deleteSnaps()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func nextPressed(_ sender: Any) {
        guard let currentViewController = pageVC.viewControllers?.first else { return }
        guard let nextViewController = pageVC.dataSource?.pageViewController(pageVC, viewControllerAfter: currentViewController) else { return }
        pageVC.setViewControllers([nextViewController], direction: .forward, animated: true) { (finished) in
            guard let currentIndex = (self.pageVC.viewControllers?.first as? SnapViewer)?.index else { return }
            if currentIndex > self.viewedSnaps {
                self.viewedSnaps = currentIndex
            }
            print(self.viewedSnaps)
        }
    }
    
    @IBAction func previousPressed(_ sender: Any) {
        guard let currentViewController = pageVC.viewControllers?.first else { return }
        guard let previousViewController = pageVC.dataSource?.pageViewController(pageVC, viewControllerBefore: currentViewController) else { return }
        pageVC.setViewControllers([previousViewController], direction: .reverse, animated: true) { (finished) in
            
        }
    }
    
    func snapsArraySorter(first: [String:Any], second: [String:Any]) -> Bool {
        if let timestamp1 = first["timestamp"] as? Double, let timestamp2 = second["timestamp"] as? Double {
            return timestamp1 < timestamp2
        }
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addChildViewController(pageVC)
        view.insertSubview(pageVC.view, belowSubview: closeBtn)
        pageVC.dataSource = self
        pageVC.delegate = self
        
        for (key,value) in snaps {
            if var snapDict = value as? [String:Any]{
                snapDict["snapUid"] = key
                snapsArray.append(snapDict)
            }
        }

        snapsArray.sort(by: snapsArraySorter)
        
        var count = 0
        for snap in snapsArray {
            let snapView = SnapViewer()
            snapView.index = count
            if let mediaType = snap["mediaType"] as? String, let databaseUrl = snap["databaseUrl"] as? String {
                if mediaType == "photo" {
                    snapView.imageView.imageFromServerURL(urlString: databaseUrl, completion: nil)
                } else if mediaType == "video" {
                    if let url = URL(string: databaseUrl) {
                        snapView.playerItem = AVPlayerItem(url: url)
                    } else {
                        print("Invalid url")
                    }
                }
                if let captionText = snap["captionText"] as? String, let captionPosY = snap["captionPosY"] as? CGFloat {
                    snapView.addCaption(editingEnabled: false)
                    snapView.captionField?.text = captionText
                    snapView.captionField?.center.y = captionPosY
                    snapView.panRecognizer = nil
                }
                if var timestamp = snap["timestamp"] as? Double {
                    timestamp = floor(timestamp/1000)
                    let date = NSDate(timeIntervalSince1970: timestamp)
                    let dateFormatter = DateFormatter()
                    dateFormatter.timeStyle = DateFormatter.Style.medium
                    dateFormatter.dateStyle = DateFormatter.Style.medium
                    dateFormatter.timeZone = TimeZone.current
                    let localTimestamp = dateFormatter.string(from: date as Date)
                    snapView.addTimestamp()
                    snapView.timestampLbl?.text = localTimestamp
                }
                snapViewControllers.append(snapView)
            } else {
                print("Error adding snapView to PVC array")
            }
            count += 1
        }
        
        if let firstVC = snapViewControllers.first {
            pageVC.setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
        }
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vcIndex = snapViewControllers.index(of: viewController as! SnapViewer) else {
            return nil
        }
        
        let previousIndex = vcIndex - 1
        
        if previousIndex < 0 {
            return nil
        } else {
            return snapViewControllers[previousIndex]
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vcIndex = snapViewControllers.index(of: viewController as! SnapViewer) else {
            return nil
        }
        
        let nextIndex = vcIndex + 1
        
        if nextIndex > snapViewControllers.count - 1 {
            return nil
        } else {
            return snapViewControllers[nextIndex]
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        guard let currentIndex = (pageVC.viewControllers?.first as? SnapViewer)?.index else { return }
        if currentIndex > viewedSnaps && completed {
            viewedSnaps = currentIndex
        }
        print(viewedSnaps)

    }
    
    func deleteSnaps() {
        for index in 0...viewedSnaps {
            if let storageName = snapsArray[index]["storageName"] as? String, let snapUid = snapsArray[index]["snapUid"] as? String {
                let currentUser = AuthService.instance.currentUser
                DataService.instance.mediaStorageRef.child(storageName).delete(completion: { (error) in
                    if error != nil {
                        print("Error deleting media from storage: \(error!)")
                    } else {
                        DataService.instance.usersRef.child(currentUser).child("snapsReceived").child(self.senderUid).child("snaps").child(snapUid).removeValue(completionBlock: { (error, ref) in
                            if error != nil {
                                print("Error deleting snap from database: \(error!)")
                            }
                        })
                    }
                })
            }
        }
    }

}
