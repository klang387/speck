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
    
    let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    var snapViewControllers = [SnapViewer]()
    
    @IBAction func closePressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var snaps = [String:Any]()
    var snapsArray = [[String:Any]]()
    
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
        
        for snap in snapsArray {
            let snapView = SnapViewer()
            if let mediaType = snap["mediaType"] as? String, let databaseUrl = snap["databaseUrl"] as? String {
                if mediaType == "photo" {
                    snapView.imageView.imageFromServerURL(urlString: databaseUrl)
                } else if mediaType == "video" {
                    if let url = URL(string: databaseUrl) {
                        snapView.playerItem = AVPlayerItem(url: url)
                    } else {
                        print("Invalid url")
                    }
                }
                snapViewControllers.append(snapView)
            } else {
                print("Error adding snapView to PVC array")
            }
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

}
