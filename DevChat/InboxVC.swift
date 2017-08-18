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

class InboxVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func backBtn(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var snapsReceived = [[String:Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        DataService.instance.receivedSnapsRef.observe(.value, with: { (snapshot) in
            print("SNAP RECEIVED!")
            self.snapsReceived.removeAll()
            if let snapUids = snapshot.value as? [String:Any] {
                for (key,_) in snapUids {
                    DataService.instance.snapsRef.child(key).observeSingleEvent(of: .value, with: { (snapshotDatabase) in
                        if var snapDetails = snapshotDatabase.value as? [String:Any] {
                            if let sender = snapDetails["sender"] as? String {
                                DataService.instance.usersRef.child(sender).child("profile").observeSingleEvent(of: .value, with: { (snapshotSender) in
                                    if let senderProfile = snapshotSender.value as? [String:Any] {
                                        snapDetails["senderProfile"] = senderProfile
                                        snapDetails["snapUid"] = key
                                        self.snapsReceived.append(snapDetails)
                                        self.tableView.reloadData()
                                    }
                                })
                            }
                        }
                    })
                }
            }
        })
    
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return snapsReceived.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as! UserCell
        let snap = snapsReceived[indexPath.row]
        let user = User(snap: snap)
        cell.updateUI(user: user)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let snap = snapsReceived[indexPath.row]
        if let url = snap["databaseUrl"] {
            performSegue(withIdentifier: "toViewSnapsVC", sender: url)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewSnapsVC = segue.destination as? ViewSnapsVC {
            viewSnapsVC.videoUrl = sender as? String
        }
    }


}
