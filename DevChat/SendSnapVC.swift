//
//  SendSnapVC.swift
//  DevChat
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
    
    var delegate: SendSnapDelegate?
    
    private var _users = [User]()
    private var _filteredUsers = [User]()
    private var _selectedUsers = [String:Bool]()
    
    private var _tempVidUrl: URL?
    private var _tempPhotoData: Data?
    
    private var _friendsObserver: UInt!
    
    var tempPhotoData: Data? {
        set {
            _tempPhotoData = newValue
        } get {
            return _tempPhotoData
        }
    }
    
    var tempVidUrl: URL? {
        set {
            _tempVidUrl = newValue
        } get {
            return _tempVidUrl
        }
    }
    
    var selectedUsers: [String:Bool] {
        set {
            _selectedUsers = newValue
        } get {
            return _selectedUsers
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserCell.self as AnyClass, forCellReuseIdentifier: "UserCell")

        searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        _friendsObserver = DataService.instance.friendsRef.observe(.value, with: { (snapshot) in
            DataService.instance.loadUsersFromSnapshot(snapshot: snapshot, completion: { userArray in
                self._users = userArray
                self._filteredUsers = self._users
                self.tableView.reloadData()
            })
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        DataService.instance.friendsRef.removeObserver(withHandle: _friendsObserver)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        _filteredUsers = searchText.isEmpty ? _users : _users.filter({ (user) -> Bool in
            return user.name.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
        })
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
        let user = _filteredUsers[indexPath.row]
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
        let user = _filteredUsers[indexPath.row]
        _selectedUsers[user.uid] = true
        delegate?.rowsAreSelected(selected: true)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! UserCell
        cell.bgView.backgroundColor = view.UIColorFromHex(rgbValue: 0xF7F7F7)
        cell.backgroundColor = view.UIColorFromHex(rgbValue: 0x9FA3A6)
        let user = _filteredUsers[indexPath.row]
        _selectedUsers[user.uid] = nil
        if _selectedUsers.count == 0 {
            delegate?.rowsAreSelected(selected: false)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _filteredUsers.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

}

protocol SendSnapDelegate {
    func rowsAreSelected(selected: Bool)
}
