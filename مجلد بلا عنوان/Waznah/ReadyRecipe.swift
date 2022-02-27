//
//  ReadyRecipe.swift
//  Waznah
//
//  Created by Anas Hamad on 26/07/1443 AH.
//

import UIKit

class ReadyRecipe: UIViewController {

    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.image = UIImage(named: "recipes4".localized)
        
    }
    


}
