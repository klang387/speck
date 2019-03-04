//
//  EulaAlertVC.swift
//  Speck
//
//  Created by Kevin Langelier on 3/4/19.
//  Copyright © 2019 Kevin Langelier. All rights reserved.
//

import UIKit

class EulaAlertVC: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var innerView: UIView!
    
    var agreeCompletion: ()->Void
    var cancelCompletion: (()->Void)?
    var alert: EulaAlertVC?
    
    
    init(agreeCompletion: @escaping ()->Void, cancelCompletion: (()->Void)? = nil) {
        self.agreeCompletion = agreeCompletion
        self.cancelCompletion = cancelCompletion
        super.init(nibName: "EulaAlertVC", bundle: Bundle(for: EulaAlertVC.self))
        alert = self
    }
    
    deinit {
        print("DEINIT")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.frame = UIApplication.shared.keyWindow!.frame
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        innerView.layer.cornerRadius = 12
        
        textView.text = Constants.eulaText
        
    }
    
    func show() {
        UIApplication.shared.keyWindow!.addSubview(view)
    }
    
    func dismiss() {
        UIApplication.shared.keyWindow!.subviews.forEach {
            if $0 == view {
                $0.removeFromSuperview()
            }
        }
        alert = nil
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        if let cancel = cancelCompletion {
            cancel()
        }
        dismiss()
    }
    
    @IBAction func agreePressed(_ sender: Any) {
        agreeCompletion()
        dismiss()
    }
    
}
