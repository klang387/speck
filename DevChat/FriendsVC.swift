//
//  FriendsVC.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/23/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit

class FriendsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UserCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBAction func backPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    let sectionHeaders = ["Friend Requests", "Friends", "All Users"]
    
    var friendRequestsArray = [User]()
    var friendsArray = [User]()
    var allUsersArray = [User]()
    var outgoingRequests = [String:Bool]()
    
    var friendsObserver: UInt!
    var friendRequestsObserver: UInt!
    var allUsersObserver: UInt!
    var outgoingRequestsObserver: UInt!
    
    var currentUser: String?
    var user: User?
    
    var section0Hidden = false
    var section1Hidden = false
    var section2Hidden = false
    
    var profilePicCache: NSCache<NSString,UIImage>!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        profilePicCache = NSCache()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserCell.self as AnyClass, forCellReuseIdentifier: "UserCell")
        
        currentUser = AuthService.instance.currentUser!
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        friendsObserver = DataService.instance.friendsRef.observe(.value, with: { (snapshot) in
            DataService.instance.loadUsers(snapshot: snapshot, completion: { userArray in
                self.friendsArray = userArray
                self.tableView.reloadData()
            })
        })
        
        friendRequestsObserver = DataService.instance.friendRequestsRef.observe(.value, with: { (snapshot) in
            DataService.instance.loadUsers(snapshot: snapshot, completion: { userArray in
                self.friendRequestsArray = userArray
                self.tableView.reloadData()
            })
        })
        
        allUsersObserver = DataService.instance.profilesRef.observe(.value, with: { (snapshot) in
            self.allUsersArray = DataService.instance.loadAllUsers(snapshot: snapshot)
            self.tableView.reloadData()
        })
        
        outgoingRequestsObserver = DataService.instance.outgoingRequestsRef.observe(.value, with: { (snapshot) in
            if let outgoingDict = snapshot.value as? [String:Bool] {
                self.outgoingRequests = outgoingDict
            } else {
                self.outgoingRequests.removeAll()
            }
            self.tableView.reloadData()
        })
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        DataService.instance.friendsRef.removeObserver(withHandle: friendsObserver)
        DataService.instance.friendRequestsRef.removeObserver(withHandle: friendRequestsObserver)
        DataService.instance.profilesRef.removeObserver(withHandle: allUsersObserver)
        DataService.instance.outgoingRequestsRef.removeObserver(withHandle: outgoingRequestsObserver)
        
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let rect = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40)
        let headerView = UIView(frame: rect)
        
        let sectionTitle = UILabel(frame: CGRect(x: 15, y: 0, width: tableView.frame.width / 2, height: 40))
        sectionTitle.font = UIFont(name: "Avenir", size: 18)
        sectionTitle.textColor = UIColor.darkGray
        headerView.addSubview(sectionTitle)
        
        let sectionCount = UILabel(frame: CGRect(x: headerView.frame.width - 30, y: 0, width: 30, height: headerView.frame.height))
        sectionCount.font = UIFont(name: "Avenir", size: 18)
        sectionCount.textColor = UIColor.darkGray
        headerView.addSubview(sectionCount)
        
        let sectionBtn = UIButton(frame: headerView.frame)
        sectionBtn.tag = section
        sectionBtn.addTarget(self, action: #selector(toggleSectionVisibility), for: .touchUpInside)
        headerView.addSubview(sectionBtn)
        
        switch section {
        case 0:
            headerView.backgroundColor = self.view.UIColorFromHex(rgbValue: 0xE1EC80)
            sectionTitle.text = "Friend Requests"
            if friendRequestsArray.count > 0 {
                sectionCount.text = String(friendRequestsArray.count)
            }
        case 1:
            headerView.backgroundColor = self.view.UIColorFromHex(rgbValue: 0x8BBFD6)
            sectionTitle.text = "Friends"
            if friendsArray.count > 0 {
                sectionCount.text = String(friendsArray.count)
            }
        case 2:
            headerView.backgroundColor = self.view.UIColorFromHex(rgbValue: 0xDCDCDC)
            sectionTitle.text = "All Users"
        default:  break
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return section0Hidden ? 0 : friendRequestsArray.count
        case 1: return section1Hidden ? 0 : friendsArray.count
        case 2: return section2Hidden ? 0 : allUsersArray.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as! UserCell
        if cell.nameLbl == nil {
            cell.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 70)
            cell.setupCell()
        }
        if cell.cellSelected {
            cell.resetCellPostion()
        }
        if cell.animateDistance! > cell.frame.height && indexPath.section != 0 {
            cell.animateDistance = cell.frame.height
        }
        if cell.iconView != nil {
            cell.iconView?.removeFromSuperview()
            cell.iconView = nil
        }
        switch indexPath.section {
        case 0:
            let user = friendRequestsArray[indexPath.row]
            cell.nameLbl.text = user.name
            getProfileImage(user: user, completion: { image in
                cell.profPic.image = image
            })
        case 1:
            let user = friendsArray[indexPath.row]
            cell.nameLbl.text = user.name
            getProfileImage(user: user, completion: { image in
                cell.profPic.image = image
            })
        case 2:
            let user = allUsersArray[indexPath.row]
            cell.nameLbl.text = user.name
            getProfileImage(user: user, completion: { image in
                cell.profPic.image = image
            })
            if checkRequestStatus(user: user) {
                cell.requestSent = true
                cell.toggleWaitingIcon()
            } else {
                cell.requestSent = false
                cell.toggleWaitingIcon()
            }
        default:
            break
        }
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? UserCell {
            switch indexPath.section {
            case 0:
                cell.toggleButtons(tableSection: 0)
                user = friendRequestsArray[indexPath.row]
            case 1:
                cell.toggleButtons(tableSection: 1)
                user = friendsArray[indexPath.row]
            case 2:
                cell.toggleButtons(tableSection: 2)
                user = allUsersArray[indexPath.row]
            default:
                break
            }
        }
        
    }
    
    func toggleSectionVisibility(sender: UIButton) {
        switch sender.tag {
        case 0:
            section0Hidden = !section0Hidden
        case 1:
            section1Hidden = !section1Hidden
        case 2:
            section2Hidden = !section2Hidden
        default:
            break
        }
        tableView.reloadData()
    }
    
    func checkRequestStatus(user: User) -> Bool {
        guard user.uid != nil else { return false }
        guard outgoingRequests[user.uid!] != nil else { return false }
        return true
    }
    
    func acceptFriendRequest() {
        if let currentUser = self.currentUser, let user = self.user?.uid {
            DataService.instance.usersRef.child(currentUser).child("friendRequests").child(user).removeValue()
            DataService.instance.usersRef.child(user).child("outgoingRequests").child(currentUser).removeValue()
            DataService.instance.usersRef.child(currentUser).child("friends").updateChildValues([user:true])
            DataService.instance.usersRef.child(user).child("friends").updateChildValues([currentUser:true])
        }
    }
    
    func deleteFriendRequest() {
        if let currentUser = self.currentUser, let user = self.user?.uid {
            DataService.instance.usersRef.child(currentUser).child("friendRequests").child(user).removeValue()
            DataService.instance.usersRef.child(user).child("outgoingRequests").child(currentUser).removeValue()
        }
    }
    
    func deleteFriend() {
        if let currentUser = self.currentUser, let user = self.user?.uid {
            DataService.instance.usersRef.child(user).child("friends").child(currentUser).removeValue()
            DataService.instance.usersRef.child(currentUser).child("friends").child(user).removeValue()
        }
    }
    
    func sendFriendRequest() {
        if let currentUser = self.currentUser, let user = self.user?.uid {
            DataService.instance.usersRef.child(user).child("friendRequests").updateChildValues([currentUser:true])
            DataService.instance.usersRef.child(currentUser).child("outgoingRequests").updateChildValues([user:true])
        }
    }
    
    func cancelFriendRequest() {
        if let currentUser = self.currentUser, let user = self.user?.uid {
            DataService.instance.usersRef.child(user).child("friendRequests").child(currentUser).removeValue()
            DataService.instance.usersRef.child(currentUser).child("outgoingRequests").child(user).removeValue()
        }
    }

    func getProfileImage(user: User, completion: @escaping (UIImage) -> Void) {
        if let image = profilePicCache.object(forKey: user.uid! as NSString) {
            print("Image from cache")
            completion(image)
        } else {
            print("Image from net")
            URLSession.shared.dataTask(with: NSURL(string: user.profPicUrl)! as URL, completionHandler: { (data, response, error) -> Void in
                if error != nil {
                    print(error!)
                    return
                }
                DispatchQueue.main.async(execute: { () -> Void in
                    if let image = UIImage(data: data!) {
                        self.profilePicCache.setObject(image, forKey: user.uid! as NSString)
                        completion(image)
                        
                    }
                })
            }).resume()
        }

    }
    
}
