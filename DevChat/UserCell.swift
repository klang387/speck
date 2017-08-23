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
    @IBOutlet weak var snapCountLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setCheckmark(selected: false)
        self.selectionStyle = .none
    }
    
    func setCheckmark(selected: Bool) {
        let imageStr = selected ? "messageChecked" : "messageUnchecked"
        self.accessoryView = UIImageView(image: UIImage(named: imageStr))
    }
    
    func updateUI(user: User, snapCount: Int?) {
        nameLbl.text = user.name
        profPic.imageFromServerURL(urlString: user.profPicUrl)
        if snapCount != nil {
            snapCountLbl.text = "\(snapCount!)"
        }
    }

}
