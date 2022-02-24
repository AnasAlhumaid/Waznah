//
//  RecepisController.swift
//  Waznah
//
//  Created by Anas Hamad on 22/07/1443 AH.
//

import Foundation
import UIKit
import CoreData


protocol UpdateDelegate {
    func didFinishUpdates(finished: Bool)
}

class RecepisController : UIViewController, UpdateDelegate {
   
    

    
    
    
    
    var delegate: UpdateDelegate?
    
    @IBOutlet var backgroungImage: UIImageView!
    @IBOutlet var cardRectangle: UIImageView!
    @IBOutlet var collictionView: UICollectionView!
    @IBOutlet var addRecepis: UIButton!
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var recepie : [Recepie] = []
   
    
    
    
    
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
        
        collictionView.delegate = self
        collictionView.dataSource = self
        
        addRecepis.backgroundColor = UIColor(displayP3Red: 0.184, green: 0.188, blue: 0.169, alpha: 1)
        addRecepis.tintColor = UIColor.white
        addRecepis.layer.cornerRadius = 15
        
        let updates = RecepisController()
            updates.delegate = self
    }
    
    
    
  
    func didFinishUpdates(finished: Bool) {
        guard finished else {
                   print("not finish")
                   return
               }
        collictionView.reloadData()
           
    }

    
    override func viewDidAppear(_ animated: Bool) {
        recepie = getData()
        collictionView.reloadData()
    }
    
 
    @IBAction func addBtn(_ sender: Any) {
        
        performSegue(withIdentifier: "addRecipes", sender: self)
        
        
    }
    
    func getData()->[Recepie]{

        let request: NSFetchRequest<Recepie> = Recepie.fetchRequest()
        var recepie : [Recepie] = []
        do{
            recepie = try context.fetch(request)
            
        }catch{
            print(error.localizedDescription)
        }
        return recepie
    }
    
}

extension RecepisController : UICollectionViewDelegate,UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        recepie.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! RecepisCell
        
        cell.typeCoffee.text = recepie[indexPath.row].roastery
        cell.typeDrip.text = recepie[indexPath.row].tools
        cell.typeRostary.text = recepie[indexPath.row].grain
        
        
        
        
        return cell
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
