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
        
        DataService.instance.receivedSnapsRef.queryOrdered(byChild: "mostRecent").observe(.value, with: { (snapshot) in
            self.snapsReceived.removeAll()
            for snap in snapshot.children.allObjects as! [DataSnapshot] {
                if var snapDict = snap.value as? [String:Any] {
                    DataService.instance.profilesRef.child(snap.key).observeSingleEvent(of: .value, with: { (snapshot) in
                        if let profile = snapshot.value as? [String:String] {
                            snapDict["name"] = profile["name"]
                            snapDict["profPicUrl"] = profile["profPicUrl"]
                            self.snapsReceived.append(snapDict)
                            self.tableView.reloadData()
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
        let fromUser = snapsReceived[indexPath.row]
        let user = User(snap: fromUser)
        let snaps = fromUser["snaps"] as? [String:Any]
        let snapCount = snaps?.count
        cell.updateUI(user: user, snapCount: snapCount)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fromUser = snapsReceived[indexPath.row]
        if let snaps = fromUser["snaps"] as? [String:Any] {
            performSegue(withIdentifier: "toViewSnapsVC", sender: snaps)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewSnapsVC = segue.destination as? ViewSnapsVC {
            viewSnapsVC.snaps = sender as! [String:Any]
        }
    }


}
