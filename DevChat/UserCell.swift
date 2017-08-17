//
//  UserCell.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/3/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit

class UserCell: UITableViewCell {

    @IBOutlet weak var firstNameLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setCheckmark(selected: false)
    }
    
    func setCheckmark(selected: Bool) {
        let imageStr = selected ? "messageChecked" : "messageUnchecked"
        self.accessoryView = UIImageView(image: UIImage(named: imageStr))
    }
    
    func updateUI(user: User) {
        firstNameLbl.text = user.firstName
    }

}
