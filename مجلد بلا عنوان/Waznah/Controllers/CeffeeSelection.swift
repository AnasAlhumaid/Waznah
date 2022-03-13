//
//  CeffeeSelection.swift
//  Waznah
//
//  Created by Anas Hamad on 07/08/1443 AH.
//

import UIKit

class CeffeeSelection: UIViewController {
    
    @IBOutlet var selectedImage: UIImageView!
    
    @IBOutlet var viewBotton: UIView!
    @IBOutlet var labelCoffee: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedImage.translatesAutoresizingMaskIntoConstraints = false
        viewBotton.translatesAutoresizingMaskIntoConstraints = false
        labelCoffee.translatesAutoresizingMaskIntoConstraints = false
        constrain()
        labelCoffee.text = "V60"
        labelCoffee.textColor = UIColor.black
        viewBotton.backgroundColor = UIColor.white.withAlphaComponent(0.4)
        viewBotton.layer.cornerRadius = 13
        
        navigationItem.title = "Make a coffee".localized
    }
    
    @IBAction func bottunAction(_ sender: UITapGestureRecognizer) {
        
        performSegue(withIdentifier: "Steps", sender: self)
    }
    
    
    func constrain(){
        
        view.addSubview(viewBotton)
        NSLayoutConstraint.activate([
            viewBotton.heightAnchor.constraint(equalToConstant:  screenWidth * 0.4),
            viewBotton.widthAnchor.constraint(equalToConstant:  screenWidth * 0.4),
            viewBotton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            viewBotton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        
        
        ])
        viewBotton.addSubview(selectedImage)
        NSLayoutConstraint.activate([
            selectedImage.heightAnchor.constraint(equalToConstant:  screenWidth * 0.5 / 2 ),
            selectedImage.widthAnchor.constraint(equalToConstant:  screenWidth * 0.4 / 2),
            selectedImage.centerXAnchor.constraint(equalTo: viewBotton.centerXAnchor),
            selectedImage.centerYAnchor.constraint(equalTo: viewBotton.centerYAnchor)
            
            
        ])
        
        viewBotton.addSubview(labelCoffee)
        NSLayoutConstraint.activate([
            labelCoffee.topAnchor.constraint(equalTo: selectedImage.bottomAnchor,constant: 5),
            labelCoffee.centerXAnchor.constraint(equalTo: viewBotton.centerXAnchor,constant: -5)

        ])
       
        
    }
}

