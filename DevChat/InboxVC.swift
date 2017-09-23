//
//  InboxVC.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/12/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class InboxVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: CustomSearchBar!
    
    @IBAction func backBtn(_ sender: Any) {
        searchBar.endEditing(true)
        AppDelegate.AppUtility.lockOrientation(.portrait)
        self.dismiss(animated: true, completion: nil)
    }
    
    var snapsReceived = [[String:Any]]()
    var filteredSnaps = [[String:Any]]()
    
    var inboxObserver: UInt!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserCell.self as AnyClass, forCellReuseIdentifier: "UserCell")
        
        searchBar.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.snapsReceived.removeAll()
        self.filteredSnaps.removeAll()
        inboxObserver = DataService.instance.receivedSnapsRef.queryOrdered(byChild: "mostRecent").observe(.value, with: { (snapshot) in
            self.snapsReceived.removeAll()
            self.filteredSnaps.removeAll()
            let sortedArray = snapshot.children.allObjects as! [DataSnapshot]
            for snap in sortedArray.reversed() {
                if var snapDict = snap.value as? [String:Any] {
                    snapDict["senderUid"] = snap.key as String
                    DataService.instance.profilesRef.child(snap.key).observeSingleEvent(of: .value, with: { (snapshot) in
                        if let profile = snapshot.value as? [String:String] {
                            snapDict["name"] = profile["name"]
                            snapDict["profPicUrl"] = profile["profPicUrl"]
                            if let _ = snapDict["snaps"] as? [String:Any] {
                                self.snapsReceived.insert(snapDict, at: 0)
                                self.filteredSnaps.insert(snapDict, at: 0)
                            } else {
                                self.snapsReceived.append(snapDict)
                                self.filteredSnaps.append(snapDict)
                            }
                            self.tableView.reloadData()
                        }
                    })
                }
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        DataService.instance.receivedSnapsRef.removeObserver(withHandle: inboxObserver)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredSnaps = searchText.isEmpty ? snapsReceived : snapsReceived.filter({ (snap) -> Bool in
            guard let name = snap["name"] as? String else { return false }
            return name.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
        })
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredSnaps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let fromUser = filteredSnaps[indexPath.row]
        let user = User(snap: fromUser)
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as! UserCell
        cell.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 70)
        cell.bgView.frame = CGRect(x: 0, y: 0.5, width: view.frame.width, height: cell.frame.height - 1)
        if cell.nameLbl == nil {
            cell.setupCell()
            cell.addSnapCount()
            cell.snapCount?.translatesAutoresizingMaskIntoConstraints = false
            cell.snapCount?.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: 0).isActive = true
            cell.snapCount?.topAnchor.constraint(equalTo: cell.topAnchor, constant: 0).isActive = true
            cell.snapCount?.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: 0).isActive = true
            cell.snapCount?.widthAnchor.constraint(equalToConstant: cell.frame.height).isActive = true
        }
        cell.nameLbl.text = user.name
        ImageCache.instance.getProfileImage(user: user, completion: { image in
            cell.profPic.image = image
        })
        cell.profPic.alpha = 1
        cell.nameLbl.alpha = 1
        cell.styleSquare?.alpha = 0.1
        if let snaps = fromUser["snaps"] as? [String:Any] {
            cell.snapCount?.text = "\(snaps.count)"
            cell.bgView.backgroundColor = view.UIColorFromHex(rgbValue: 0x94C4D8)
            cell.backgroundColor = .white
            return cell
        } else {
            cell.profPic.alpha = 0.5
            cell.nameLbl.alpha = 0.5
            cell.styleSquare?.alpha = 0.01
            cell.snapCount?.text = ""
            cell.bgView.backgroundColor = view.UIColorFromHex(rgbValue: 0xF3F3F3)
            cell.backgroundColor = view.UIColorFromHex(rgbValue: 0x9FA3A6)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fromUser = snapsReceived[indexPath.row]
        if var snaps = fromUser["snaps"] as? [String:Any] {
            snaps["senderUid"] = fromUser["senderUid"]
            performSegue(withIdentifier: "toViewSnapsVC", sender: snaps)
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewSnapsVC = segue.destination as? ViewSnapsVC {
            viewSnapsVC.snaps = sender as! [String:Any]
            viewSnapsVC.senderUid = viewSnapsVC.snaps["senderUid"] as! String
        }
    }

}
