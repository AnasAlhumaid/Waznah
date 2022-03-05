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
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var ratioTitel: UILabel!
    @IBOutlet var prepareTitel: UILabel!
    @IBOutlet var roasteryTitel: UILabel!
    @IBOutlet var tempTitel: UILabel!
    @IBOutlet var grainTitel: UILabel!
    @IBOutlet var toolTitel: UILabel!
    
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
        imageView.image = UIImage(named: "pdfPrevew".localized)
        
        //func for loclized
        loclizablefun()
    }
    
    func loclizablefun(){
        
        toolTitel.text = "Tool".localized
        grainTitel.text = "Grind".localized
        tempTitel.text = "Temperature".localized
        roasteryTitel.text = "Roastery".localized
        prepareTitel.text = "Prepare".localized
        ratioTitel.text = "Ratio".localized
        
    }
    
    @IBAction func ShareBtn(_ sender: Any) {
        
        let screenShot = self.view.takeScreenshot()
        let imageShare = [ screenShot ]
        let activityViewController = UIActivityViewController(activityItems: imageShare ,
                                                              applicationActivities: nil)
        
        activityViewController.popoverPresentationController?.sourceView = self.view
        
        self.present(activityViewController,
                     animated: true,
                     completion: nil)
    }
}


extension UIView {
    
    func takeScreenshot() -> UIImage {
        
        let scale = UIScreen.main.scale
        let bonds = self.bounds
        
        UIGraphicsBeginImageContextWithOptions(bonds.size, false, scale)
        if let _ = UIGraphicsGetCurrentContext() {
            
            self.drawHierarchy(
                in: bonds,
                afterScreenUpdates: true)
            
            let screenshot = UIGraphicsGetImageFromCurrentImageContext()!
            
            UIGraphicsEndImageContext()
            
            return screenshot
        }
        
        return UIImage()
    }
    
}
