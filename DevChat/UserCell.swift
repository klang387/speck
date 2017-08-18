//
//  UserCell.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/3/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit

class UserCell: UITableViewCell {

    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var profPic: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setCheckmark(selected: false)
        self.selectionStyle = .none
    }
    
    func setCheckmark(selected: Bool) {
        let imageStr = selected ? "messageChecked" : "messageUnchecked"
        self.accessoryView = UIImageView(image: UIImage(named: imageStr))
    }
    
    func updateUI(user: User) {
        nameLbl.text = user.firstName.capitalized + " " + user.lastName.capitalized
        profPic.imageFromServerURL(urlString: user.profPicUrl)
    }

}
