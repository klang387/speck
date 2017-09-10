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
    var cellSelected = false
    var button1: UIButton?
    var button2: UIButton?
    var animateDistance: CGFloat?
    var snapCount: UILabel?
    var requestSent = false
    var iconView: UIImageView?
    
    var delegate: UserCellDelegate?
    
    func setupCell() {
        animateDistance = frame.height
        selectionStyle = .none
        backgroundColor = UIColorFromHex(rgbValue: 0xF7F7F7)
        let height: CGFloat = 54
        let width: CGFloat = 54
        profPic = UIImageView(frame: CGRect(x: frame.height / 2 - width / 2, y: frame.midY - height / 2, width: width, height: height))
        profPic.layer.cornerRadius = height / 2
        profPic.layer.masksToBounds = true
        nameLbl = UILabel(frame: CGRect(x: profPic.frame.maxX + 25, y: profPic.frame.minY, width: 200, height: height))
        nameLbl.font = UIFont(name: "Avenir", size: 18)
        nameLbl.textColor = UIColor.darkGray
        
        addSubview(profPic)
        addSubview(nameLbl)
    }
    
    func updateUI(user: User) {
        nameLbl.text = user.name
        profPic.imageFromServerURL(urlString: user.profPicUrl, completion: nil)
    }
    
    func addStyleSquare(alignment: String) {
        var rect = CGRect(x: 0, y: 0, width: frame.height, height: frame.height)
        if alignment == "right" {
            rect = CGRect(x: frame.width - frame.height, y: 0, width: frame.height, height: frame.height)
        }
        let styleSquare = UIView(frame: rect)
        styleSquare.backgroundColor = UIColor.black
        styleSquare.alpha = 0.1
        insertSubview(styleSquare, belowSubview: profPic)
    }
    
    func addSnapCount() {
        snapCount = UILabel(frame: CGRect(x: frame.width - frame.height, y: 0, width: frame.height, height: frame.height))
        snapCount?.font = UIFont(name: "Avenir", size: 16)
        snapCount?.textAlignment = .center
        snapCount?.textColor = UIColor.darkGray
        addSubview(snapCount!)
    }
    
    func toggleWaitingIcon() {
    if requestSent {
            iconView = UIImageView(frame: CGRect(x: frame.width - frame.height, y: 0, width: frame.height, height: frame.height))
            iconView?.image = UIImage(named: "RequestWaiting")
            iconView?.contentMode = .center
            addSubview(iconView!)
        } else {
            iconView?.removeFromSuperview()
            iconView = nil
        }
    }
    
    func toggleButtons(tableSection: Int) {
        cellSelected = cellSelected ? false : true
        if cellSelected {
            button1 = UIButton(frame: CGRect(x: frame.width, y: 0, width: frame.height, height: frame.height))
            button1?.backgroundColor = UIColorFromHex(rgbValue: 0xEAEAEA)
            addSubview(button1!)
            switch tableSection {
            case 0:
                button1?.setImage(UIImage(named: "Delete"), for: .normal)
                button1?.addTarget(self, action: #selector(deleteRequest), for: .touchUpInside)
                button2 = UIButton(frame: CGRect(x: frame.width + frame.height + 2, y: 0, width: frame.height, height: frame.height))
                button2?.backgroundColor = UIColorFromHex(rgbValue: 0xEAEAEA)
                button2?.setImage(UIImage(named: "Accept"), for: .normal)
                button2?.addTarget(self, action: #selector(acceptRequest), for: .touchUpInside)
                addSubview(button2!)
                self.animateDistance = frame.height * 2 + 2
            case 1:
                button1?.setImage(UIImage(named: "Delete"), for: .normal)
                button1?.addTarget(self, action: #selector(deleteFriend), for: .touchUpInside)
            case 2:
                if !requestSent {
                    button1?.setImage(UIImage(named: "RequestAdd"), for: .normal)
                    button1?.addTarget(self, action: #selector(sendRequest), for: .touchUpInside)
                } else {
                    button1?.setImage(UIImage(named: "RequestRemove"), for: .normal)
                    button1?.addTarget(self, action: #selector(cancelRequest), for: .touchUpInside)
                }
            default:
                break
            }
            
            guard animateDistance != nil else { return }

            UIView.animate(withDuration: 0.2, animations: {
                self.nameLbl.frame.origin.x -= self.frame.height
                self.profPic.frame.origin.x -= self.frame.height
                self.nameLbl.textColor = UIColor.lightGray
                self.button1?.frame.origin.x -= self.animateDistance!
                if self.button2 != nil {
                    self.button2?.frame.origin.x -= self.animateDistance!
                }
            }) { (finished) in
                // Animation Completion Handler
            }
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                self.nameLbl.frame.origin.x += self.frame.height
                self.profPic.frame.origin.x += self.frame.height
                self.nameLbl.textColor = UIColor.darkGray
                self.button1?.frame.origin.x += self.animateDistance!
                if self.button2 != nil {
                    self.button2?.frame.origin.x += self.animateDistance!
                }
            }) { (finished) in
                self.button1?.removeFromSuperview()
                if self.button2 != nil {
                    self.button2?.removeFromSuperview()
                }
                // Animation Completion Handler
            }
        }
        
    }
    
    func resetCellPostion() {
        cellSelected = false
        self.nameLbl.frame.origin.x += self.frame.height
        self.profPic.frame.origin.x += self.frame.height
        self.nameLbl.textColor = UIColor.darkGray
        self.button1?.removeFromSuperview()
        self.button1 = nil
        if self.button2 != nil {
            self.button2?.removeFromSuperview()
            self.button2 = nil
        }
    }
    
    func acceptRequest(sender:UIButton) {
        delegate?.acceptFriendRequest()
    }
    
    func deleteRequest(sender:UIButton) {
        delegate?.deleteFriendRequest()
    }
    
    func deleteFriend(sender:UIButton) {
        delegate?.deleteFriend()
    }
    
    func sendRequest(sender:UIButton) {
        delegate?.sendFriendRequest()
    }
    
    func cancelRequest(sender:UIButton) {
        delegate?.cancelFriendRequest()
    }

}

protocol UserCellDelegate {
    func acceptFriendRequest()
    func deleteFriendRequest()
    func deleteFriend()
    func sendFriendRequest()
    func cancelFriendRequest()
}
