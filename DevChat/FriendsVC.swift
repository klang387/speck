//
//  FriendsVC.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/23/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit

class FriendsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBAction func backPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    let sectionHeaders = ["Friend Requests", "Friends", "All Users"]
    
    var friendRequestsArray = [User]()
    var friendsArray = [User]()
    var allUsersArray = [User]()
    
    var friendsObserver: UInt!
    var friendRequestsObserver: UInt!
    var allUsersObserver: UInt!
    
    var myProfile = [String:Any]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserCell.self as AnyClass, forCellReuseIdentifier: "UserCell")
        
        let currentUser = AuthService.instance.currentUser!
        DataService.instance.profilesRef.child(currentUser).observeSingleEvent(of: .value, with: { (snapshot) in
            if let profile = snapshot.value as? [String:Any] {
                self.myProfile[currentUser] = profile
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        friendsObserver = DataService.instance.friendsRef.observe(.value, with: { (snapshot) in
            self.friendsArray = DataService.instance.loadUsers(snapshot: snapshot)
            self.tableView.reloadData()
        })
        
        friendRequestsObserver = DataService.instance.friendRequestsRef.observe(.value, with: { (snapshot) in
            self.friendRequestsArray = DataService.instance.loadUsers(snapshot: snapshot)
            self.tableView.reloadData()
        })
        
        allUsersObserver = DataService.instance.profilesRef.observe(.value, with: { (snapshot) in
            self.allUsersArray = DataService.instance.loadUsers(snapshot: snapshot)
            self.tableView.reloadData()
        })
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        DataService.instance.friendsRef.removeObserver(withHandle: friendsObserver)
        DataService.instance.friendRequestsRef.removeObserver(withHandle: friendRequestsObserver)
        DataService.instance.profilesRef.removeObserver(withHandle: allUsersObserver)
        
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        print("viewForHeader")
        let rect = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40)
        let headerView = UIView(frame: rect)
        let sectionTitle = UILabel(frame: CGRect(x: 15, y: 0, width: tableView.frame.width / 2, height: 40))
        sectionTitle.font = UIFont(name: "Avenir", size: 18)
        sectionTitle.textColor = UIColor.darkGray
        headerView.addSubview(sectionTitle)
        
        switch section {
        case 0:
            headerView.backgroundColor = UIColorFromHex(rgbValue: 0xCCD677)
            sectionTitle.text = "Friend Requests"
        case 1:
            headerView.backgroundColor = UIColorFromHex(rgbValue: 0xE1EC80)
            sectionTitle.text = "Friends"
        case 2:
            headerView.backgroundColor = UIColorFromHex(rgbValue: 0xEDF4B2)
            sectionTitle.text = "All Users"
        default:  break
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return friendRequestsArray.count
        case 1: return friendsArray.count
        case 2: return allUsersArray.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("creating cell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as! UserCell
        if cell.nameLbl == nil {
            cell.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 70)
            cell.setupCell(rowHeight: tableView.rectForRow(at: indexPath).size.height)
        }
        switch indexPath.section {
        case 0:
            cell.updateUI(user: friendRequestsArray[indexPath.row], snapCount: nil)
        case 1:
            cell.updateUI(user: friendsArray[indexPath.row], snapCount: nil)
        default:
            cell.updateUI(user: allUsersArray[indexPath.row], snapCount: nil)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            if let currentUser = AuthService.instance.currentUser {
                print("Accepting friend request")
                let user = friendRequestsArray[indexPath.row]
                let userDict: [String:Any] = [user.uid!:["name": user.name, "profPicUrl":user.profPicUrl]]
                DataService.instance.usersRef.child(currentUser).child("friendRequests").child(user.uid!).removeValue()
                DataService.instance.usersRef.child(currentUser).child("friends").updateChildValues(userDict)
            }
        case 1:
            if let user = friendsArray[indexPath.row].uid, let currentUser = AuthService.instance.currentUser {
                print("Deleting friend")
                DataService.instance.usersRef.child(user).child("friends").child(currentUser).removeValue()
                DataService.instance.usersRef.child(currentUser).child("friends").child(user).removeValue()
            }
        default:
            if let user = allUsersArray[indexPath.row].uid {
                print("Uploading friend request")
                DataService.instance.usersRef.child(user).child("friendRequests").updateChildValues(myProfile)
            }
        }
        
    }
    
    func UIColorFromHex(rgbValue:UInt32, alpha:Double=1.0)->UIColor {
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        
        return UIColor(red:red, green:green, blue:blue, alpha:CGFloat(alpha))
    }
}
