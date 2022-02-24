//
//  DetailRecepis.swift
//  Waznah
//
//  Created by Anas Hamad on 22/07/1443 AH.
//

import UIKit

class DetailRecepis: UIViewController {

    @IBOutlet var imageBackgraund: UIImageView!
    @IBOutlet var moreTools: UITextField!
    @IBOutlet var tfGrain: UITextField!
    @IBOutlet var tFTemp: UITextField!
    @IBOutlet var tVPrepare: UITextView!
    @IBOutlet var tfRoastery: UITextField!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissTap))
        view.addGestureRecognizer(tap)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
       
    }
    
    @objc func dismissTap() {
        tfGrain.resignFirstResponder()
        tfRoastery.resignFirstResponder()
        tFTemp.resignFirstResponder()
        tVPrepare.resignFirstResponder()
        moreTools.resignFirstResponder()
    }


}
