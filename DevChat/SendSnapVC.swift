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

class SendSnapVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var delegate: SendSnapDelegate?
    
    private var _users = [User]()
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

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        _friendsObserver = DataService.instance.friendsRef.observe(.value, with: { (snapshot) in
            self._users = DataService.instance.loadUsers(snapshot: snapshot)
            print("USERS: \(self._users)")
            self.tableView.reloadData()
        })
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        DataService.instance.friendsRef.removeObserver(withHandle: _friendsObserver)
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as! UserCell
        let user = _users[indexPath.row]
        cell.updateUI(user: user, snapCount: nil)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! UserCell
        cell.setAccessoryView(imageStr: "CheckboxFilled")
        let user = _users[indexPath.row]
        _selectedUsers[user.uid!] = true
        delegate?.rowsAreSelected(selected: true)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! UserCell
        cell.setAccessoryView(imageStr: "CheckboxEmpty")
        let user = _users[indexPath.row]
        _selectedUsers[user.uid!] = nil
        if _selectedUsers.count == 0 {
            delegate?.rowsAreSelected(selected: false)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _users.count
    }

}

protocol SendSnapDelegate {
    func rowsAreSelected(selected: Bool)
}
