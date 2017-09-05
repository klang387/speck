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
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeaders[section]
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        <#code#>
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return friendRequestsArray.count
        case 1: return friendsArray.count
        case 2: return allUsersArray.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UserCell
        cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as! UserCell
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
}
