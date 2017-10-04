//
//  FriendsVC.swift
//  Speck
//
//  Created by Kevin Langelier on 8/23/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit

class FriendsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UserCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: CustomSearchBar!
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!
    
    let sectionHeaders = ["Friend Requests", "Friends", "All Users"]
    var friendRequestsArray = [User]()
    var friendsArray = [User]()
    var allUsersArray = [User]()
    var outgoingRequests = [String:Bool]()
    var filteredFriendRequests = [User]()
    var filteredFriends = [User]()
    var filteredAllUsers = [User]()
    var friendsObserver: UInt!
    var friendRequestsObserver: UInt!
    var outgoingRequestsObserver: UInt!
    var observersLoading = [true,true,false,true]
    var currentUser: String!
    var user: User?
    var section0Hidden = false
    var section1Hidden = false
    var section2Hidden = false
    var allUsersHaveLoaded = false
    var numberOfUsersToLoad: UInt = 5
    var allUsersFilterCount: UInt = 0
    var tempCounter: UInt = 0
    var searching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserCell.self as AnyClass, forCellReuseIdentifier: "UserCell")
        tableView.isHidden = true
        
        searchBar.delegate = self
        
        currentUser = AuthService.instance.currentUser
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        friendRequestsObserver = DataService.instance.friendRequestsRef.observe(.value, with: { (snapshot) in
            self.observersLoading[0] = true
            DataService.instance.loadUsersFromSnapshot(snapshot: snapshot, completion: { userArray in
                self.friendRequestsArray = userArray
                self.filteredFriendRequests = self.friendRequestsArray
                if self.observersLoading[2] == false {
                    self.loadMoreUsers()
                }
                self.observersLoading[0] = false
                if !self.loading() {
                    self.tableView.isHidden = false
                    self.activitySpinner.stopAnimating()
                    self.tableView.reloadData()
                }
            })
        })
        
        friendsObserver = DataService.instance.friendsRef.observe(.value, with: { (snapshot) in
            self.observersLoading[1] = true
            DataService.instance.loadUsersFromSnapshot(snapshot: snapshot, completion: { userArray in
                self.friendsArray = userArray.sorted(by: { (user1, user2) -> Bool in
                    user1.name < user2.name
                })
                self.filteredFriends = self.friendsArray
                if self.observersLoading[2] == false {
                    self.loadMoreUsers()
                }
                self.observersLoading[1] = false
                if !self.loading() {
                    self.tableView.isHidden = false
                    self.activitySpinner.stopAnimating()
                    self.tableView.reloadData()
                }
            })
        })
        
        outgoingRequestsObserver = DataService.instance.outgoingRequestsRef.observe(.value, with: { (snapshot) in
            self.observersLoading[3] = true
            if let outgoingDict = snapshot.value as? [String:Bool] {
                self.outgoingRequests = outgoingDict
            } else {
                self.outgoingRequests.removeAll()
            }
            self.observersLoading[3] = false
            if !self.loading() {
                self.tableView.isHidden = false
                self.activitySpinner.stopAnimating()
                self.tableView.reloadData()
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        DataService.instance.friendsRef.removeObserver(withHandle: friendsObserver)
        DataService.instance.friendRequestsRef.removeObserver(withHandle: friendRequestsObserver)
        DataService.instance.outgoingRequestsRef.removeObserver(withHandle: outgoingRequestsObserver)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.reloadData()
    }
    
    func loading() -> Bool {
        for status in observersLoading {
            if status {
                return true
            }
        }
        return false
    }
    
    func loadMoreUsers() {
        self.observersLoading[2] = true
        DataService.instance.profilesRef.queryLimited(toFirst: numberOfUsersToLoad).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.childrenCount < self.numberOfUsersToLoad {
                self.allUsersHaveLoaded = true
            } else {
                self.allUsersHaveLoaded = false
            }
            self.tempCounter = 0
            let tempArray = DataService.instance.loadAllUsers(snapshot: snapshot).filter({ (user) -> Bool in
                for friend in self.friendsArray {
                    if user.uid == friend.uid {
                        self.tempCounter += 1
                        return false
                    }
                }
                for request in self.friendRequestsArray {
                    if user.uid == request.uid {
                        self.tempCounter += 1
                        return false
                    }
                }
//                if user.uid == AuthService.instance.currentUser {
//                    self.tempCounter += 1
//                    return false
//                }
                return true
            })
            if self.tempCounter > self.allUsersFilterCount {
                self.numberOfUsersToLoad += self.tempCounter - self.allUsersFilterCount
                self.allUsersFilterCount = self.tempCounter
                self.loadMoreUsers()
                return
            }
            self.allUsersArray = tempArray
            self.filteredAllUsers = self.searchBar.text == nil || self.searchBar.text == "" ? self.allUsersArray : self.allUsersArray.filter({ (user) -> Bool in
                return user.name.range(of: self.searchBar.text!, options: .caseInsensitive, range: nil, locale: nil) != nil
            })
            self.observersLoading[2] = false
            if !self.loading() {
                self.tableView.isHidden = false
                self.activitySpinner.stopAnimating()
                self.tableView.reloadData()
            }
        })
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
            headerView.backgroundColor = self.view.UIColorFromHex(rgbValue: 0x4A5258)
            sectionTitle.text = "All Users"
            sectionTitle.textColor = .white
        default:  break
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return section0Hidden ? 0 : filteredFriendRequests.count
        case 1: return section1Hidden ? 0 : filteredFriends.count
        case 2: return section2Hidden ? 0 : allUsersHaveLoaded && !searching ? filteredAllUsers.count : filteredAllUsers.count + 1
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as! UserCell
        cell.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 70)
        cell.bgView.frame = CGRect(x: 0, y: 0.5, width: view.frame.width, height: cell.frame.height - 1)
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
        cell.profPic.image = nil
        switch indexPath.section {
        case 0:
            let user = filteredFriendRequests[indexPath.row]
            cell.nameLbl.text = user.name
            ImageCache.instance.getProfileImage(user: user, completion: { image in
                cell.profPic.image = image
            })
        case 1:
            let user = filteredFriends[indexPath.row]
            cell.nameLbl.text = user.name
            ImageCache.instance.getProfileImage(user: user, completion: { image in
                cell.profPic.image = image
            })
        case 2:
            if indexPath.row == filteredAllUsers.count {
                let loadMore = UITableViewCell(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 70))
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 70))
                label.text = "Load More Users"
                label.textAlignment = .center
                label.font = UIFont(name: "Avenir", size: 14)
                label.numberOfLines = 1
                loadMore.addSubview(label)
                if searching {
                    label.text = "Search All Users"
                }
                return loadMore
            }
            let user = filteredAllUsers[indexPath.row]
            cell.nameLbl.text = user.name
            ImageCache.instance.getProfileImage(user: user, completion: { image in
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
                user = filteredFriendRequests[indexPath.row]
            case 1:
                cell.toggleButtons(tableSection: 1)
                user = filteredFriends[indexPath.row]
            case 2:
                cell.toggleButtons(tableSection: 2)
                user = filteredAllUsers[indexPath.row]
            default:
                break
            }
        } else if indexPath.section == 2 && indexPath.row == filteredAllUsers.count {
            if searching {
                let cell = tableView.cellForRow(at: indexPath)!
                for view in cell.subviews {
                    if view.isKind(of: UILabel.self) {
                        view.removeFromSuperview()
                    }
                }
                let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
                cell.addSubview(spinner)
                spinner.center.x = cell.bounds.midX
                spinner.center.y = cell.bounds.midY
                spinner.startAnimating()
                
                if searchBar.text?.range(of: "@") == nil {
                    DataService.instance.searchDatabaseForUser(searchTerm: searchBar.text!, completion: { users in
                        spinner.removeFromSuperview()
                        self.filteredAllUsers = users
                        self.tableView.reloadData()
                    })
                } else {
                    DataService.instance.searchUsersByEmail(searchTerm: searchBar.text!, handler: { users in
                        spinner.removeFromSuperview()
                        self.filteredAllUsers = users
                        self.tableView.reloadData()
                    })
                }
            } else {
                numberOfUsersToLoad += 5
                loadMoreUsers()
            }
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
    }
    
    @objc func toggleSectionVisibility(sender: UIButton) {
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
        guard outgoingRequests[user.uid] != nil else { return false }
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
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searching = !searchText.isEmpty
        filteredFriendRequests = searchText.isEmpty ? friendRequestsArray : friendRequestsArray.filter({ (user) -> Bool in
            return user.name.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
        })
        filteredFriends = searchText.isEmpty ? friendsArray : friendsArray.filter({ (user) -> Bool in
            return user.name.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
        })
        filteredAllUsers = searchText.isEmpty ? allUsersArray : allUsersArray.filter({ (user) -> Bool in
            return user.name.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
        })
        tableView.reloadData()
    }
    
}
