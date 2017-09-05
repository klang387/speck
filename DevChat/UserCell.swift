//
//  UserCell.swift
//  DevChat
//
//  Created by Kevin Langelier on 8/3/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit

class UserCell: UITableViewCell {
    
    var profPic: UIImageView!
    var nameLbl: UILabel!
    var icon: UIImageView!
    var snapCountLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let height: CGFloat = 36
        let width: CGFloat = 36
        profPic = UIImageView(frame: CGRect(x: frame.width / 10, y: frame.midY - height / 2, width: width, height: height))
        profPic.layer.cornerRadius = 18.0
        profPic.layer.masksToBounds = true
        nameLbl = UILabel(frame: CGRect(x: profPic.frame.maxX + 20, y: profPic.frame.minY, width: 200, height: height))
        nameLbl.font = UIFont(name: "Avenir", size: 18)
        icon = UIImageView()
        snapCountLbl = UILabel()
        
        addSubview(profPic)
        addSubview(nameLbl)
        addSubview(icon)
        icon.addSubview(snapCountLbl)
        
        setAccessoryView(imageStr: "CheckboxEmpty")
        self.selectionStyle = .none
    }
    
    func setAccessoryView(imageStr: String) {
        self.accessoryView = UIImageView(image: UIImage(named: imageStr))
    }
    
//    func setCheckmark(selected: Bool) {
//        let imageStr = selected ? "messageChecked" : "messageUnchecked"
//        self.accessoryView = UIImageView(image: UIImage(named: imageStr))
//    }
    
    func updateUI(user: User, snapCount: Int?) {
        nameLbl.text = user.name
        profPic.imageFromServerURL(urlString: user.profPicUrl)
        if snapCount != nil {
            snapCountLbl.text = "\(snapCount!)"
        }
    }

}
