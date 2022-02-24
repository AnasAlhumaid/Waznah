//
//  RecepisController.swift
//  Waznah
//
//  Created by Anas Hamad on 22/07/1443 AH.
//

import Foundation
import UIKit


class RecepisController:UIViewController {
    
    
    
    
    @IBOutlet var backgroungImage: UIImageView!
    @IBOutlet var cardRectangle: UIImageView!
    @IBOutlet var collictionView: UICollectionView!
    @IBOutlet var addRecepis: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    
        
        backgroungImage.translatesAutoresizingMaskIntoConstraints = false
        backgroungImage.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5).isActive = true
        backgroungImage.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        backgroungImage.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        backgroungImage.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        cardRectangle.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        cardRectangle.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        cardRectangle.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
    
        
    }
    
 
    @IBAction func addBtn(_ sender: Any) {
        
        performSegue(withIdentifier: "addRecipes", sender: self)
        
        
    }
    
}

//extension RecepisController : UICollectionViewDelegate,UICollectionViewDataSource {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        <#code#>
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        <#code#>
//    }
//    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
//}
