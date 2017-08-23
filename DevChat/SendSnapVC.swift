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
    
    @IBAction func sendBtnPressed(_ sender: Any) {

        DataService.instance.uploadMedia(tempVidUrl: _tempVidUrl, tempPhotoData: _tempPhotoData, caption: nil, recipients: _selectedUsers, completion: { completion in
            self.dismiss(animated: true, completion: nil)
        })
        
    }
    
    @IBAction func backBtnPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private var _users = [User]()
    private var _selectedUsers = [String:Bool]()
    
    private var _tempVidUrl: URL?
    private var _tempPhotoData: Data?
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        DataService.instance.loadUsers(completion: { () in
            self._users = DataService.instance.users
            self.tableView.reloadData()
        })
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as! UserCell
        let user = _users[indexPath.row]
        cell.updateUI(user: user, snapCount: nil)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! UserCell
        cell.setCheckmark(selected: true)
        let user = _users[indexPath.row]
        _selectedUsers[user.uid!] = true
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! UserCell
        cell.setCheckmark(selected: false)
        let user = _users[indexPath.row]
        _selectedUsers[user.uid!] = nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _users.count
    }

}
