//
//  PDFGenerate.swift
//  Waznah
//
//  Created by Anas Hamad on 25/07/1443 AH.
//

import Foundation
import CoreGraphics
import UIKit
import PDFKit

class PDFGenerate : UIViewController{
    @IBOutlet var toolLabel: UILabel!
    @IBOutlet var grainLabel: UILabel!
    @IBOutlet var tempLabel: UILabel!
    @IBOutlet var roasteryLabel: UILabel!
    @IBOutlet var preparetionLabel: UILabel!
    @IBOutlet var ratioLabel: UILabel!
    @IBOutlet var ShareBottun: UIButton!
    var selectedTool : String!
    var selectedGrain : String!
    var selectedTemp : String!
    var selectedRoastery : String!
    var selectedPrepare :String!
    var selectedRatio : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toolLabel.text = selectedTool
        grainLabel.text = selectedGrain
        tempLabel.text = selectedTemp
        roasteryLabel.text = selectedRoastery
        preparetionLabel.text = selectedPrepare
        ratioLabel.text = selectedRatio
        preparetionLabel.sizeToFit()
        
       
        
    }
    
    
    
    @IBAction func ShareBtn(_ sender: Any) {
        
        
        
        
        
    }
    
    
    
}
