//
//  AppDelegate.swift
//  Speck
//
//  Created by Kevin Langelier on 7/20/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit
import Firebase
import FacebookCore
import FacebookLogin
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var orientationLock = UIInterfaceOrientationMask.all

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        AppEventsLogger.activate(application)
        
        application.registerForRemoteNotifications()
        
        if UserDefaults.standard.integer(forKey: "firstRun") != 1 {
            do {
                try Auth.auth().signOut()
                UserDefaults.standard.removeObject(forKey: "facebookLogin")
                UserDefaults.standard.set(1, forKey: "firstRun")
                UserDefaults.standard.synchronize()
            } catch {}
        }
        
        AuthService.instance.eulaApproved = UserDefaults.standard.bool(forKey: "eulaApproved")
        
        let color = UIView().UIColorFromHex(rgbValue: 0xDEED78)
        window?.backgroundColor = color
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return SDKApplicationDelegate.shared.application(app, open: url, options: options)
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }
    
    struct AppUtility {
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.orientationLock = orientation
            }
        }
        
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
            self.lockOrientation(orientation)
            UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        ImageCache.instance.purgeCache()
        URLCache.shared.removeAllCachedResponses()
        UserDefaults.standard.set(AuthService.instance.eulaApproved, forKey: "eulaApproved")
        if !AuthService.instance.eulaApproved {
            try? Auth.auth().signOut()
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        application.applicationIconBadgeNumber = 0
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

