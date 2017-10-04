//
//  SendSnapVC.swift
//  Speck
//
//  Created by Kevin Langelier on 8/3/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage

class SendSnapVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: CustomSearchBar!
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedUsers = [String:Bool]()
    var tempVidUrl: URL?
    var tempPhotoData: Data?
    var friendsObserver: UInt!
    
    var delegate: SendSnapDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserCell.self as AnyClass, forCellReuseIdentifier: "UserCell")

        searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        friendsObserver = DataService.instance.friendsRef.observe(.value, with: { (snapshot) in
            DataService.instance.loadUsersFromSnapshot(snapshot: snapshot, completion: { userArray in
                self.users = userArray
                self.filteredUsers = self.users
                self.tableView.reloadData()
            })
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        DataService.instance.friendsRef.removeObserver(withHandle: friendsObserver)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as! UserCell
        cell.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 70)
        cell.bgView.frame = CGRect(x: 0, y: 0.5, width: view.frame.width, height: cell.frame.height - 1)
        if cell.nameLbl == nil {
            cell.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 70)
            cell.setupCell()
        }
        let user = filteredUsers[indexPath.row]
        cell.nameLbl.text = user.name
        ImageCache.instance.getProfileImage(user: user, completion: { image in
            cell.profPic.image = image
        })
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! UserCell
        cell.bgView.backgroundColor = view.UIColorFromHex(rgbValue: 0xE1EC80)
        cell.backgroundColor = .white
        let user = filteredUsers[indexPath.row]
        selectedUsers[user.uid] = true
        delegate?.rowsAreSelected(selected: true)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! UserCell
        cell.bgView.backgroundColor = view.UIColorFromHex(rgbValue: 0xF7F7F7)
        cell.backgroundColor = view.UIColorFromHex(rgbValue: 0x9FA3A6)
        let user = filteredUsers[indexPath.row]
        selectedUsers[user.uid] = nil
        if selectedUsers.count == 0 {
            delegate?.rowsAreSelected(selected: false)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredUsers.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredUsers = searchText.isEmpty ? users : users.filter({ (user) -> Bool in
            return user.name.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
        })
        tableView.reloadData()
    }

}

protocol SendSnapDelegate {
    func rowsAreSelected(selected: Bool)
}
