//
//  LoadingView.swift
//  DevChat
//
//  Created by Kevin Langelier on 9/25/17.
//  Copyright © 2017 Kevin Langelier. All rights reserved.
//

import UIKit

class LoadingView: UIButton {

    func text(text: String) {
        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        
        let centerSquare = UIView()
        addSubview(centerSquare)
        centerSquare.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        centerSquare.layer.cornerRadius = 10
        centerSquare.layer.masksToBounds = true
        centerSquare.translatesAutoresizingMaskIntoConstraints = false
        centerSquare.widthAnchor.constraint(equalToConstant: 200).isActive = true
        centerSquare.heightAnchor.constraint(equalToConstant: 200).isActive = true
        centerSquare.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        centerSquare.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = UIFont(name: "Avenir", size: 18)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        centerSquare.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: centerSquare.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: centerSquare.centerYAnchor, constant: -20).isActive = true
        label.widthAnchor.constraint(equalTo: centerSquare.widthAnchor, multiplier: 0.8).isActive = true
        
        let spinner = UIActivityIndicatorView()
        centerSquare.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerXAnchor.constraint(equalTo: centerSquare.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: centerSquare.centerYAnchor, constant: 20).isActive = true
        spinner.startAnimating()
    }

}
