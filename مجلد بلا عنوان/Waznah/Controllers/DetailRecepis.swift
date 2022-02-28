//
//  DetailRecepis.swift
//  Waznah
//
//  Created by Anas Hamad on 22/07/1443 AH.
//

import UIKit
import CoreData

class DetailRecepis: UIViewController  {
    
    
    @IBOutlet var imageBackgraund: UIImageView!
    @IBOutlet var moreTools: UITextField!
    @IBOutlet var tfGrain: UITextField!
    @IBOutlet var tFTemp: UITextField!
    @IBOutlet var tVPrepare: UITextView!
    @IBOutlet var tfRoastery: UITextField!
    @IBOutlet var v60Bottun: UIButton!
    @IBOutlet var chimixBottun: UIButton!
    @IBOutlet var calitaBottun: UIButton!
    @IBOutlet var addBottun: UIButton!
    @IBOutlet var tfRatio: UITextField!
    
    @IBOutlet var toolTitel: UILabel!
    @IBOutlet var grainTitel: UILabel!
    @IBOutlet var tempTitel: UILabel!
    @IBOutlet var prepareTitel: UILabel!
    @IBOutlet var roasteryTitel: UILabel!
    @IBOutlet var ratioTitel: UILabel!
    
    
    
    var isv60 = false
    var isChimix = false
    var isCalita = false
    var delegate: UpdateDelegate?
    
    @IBOutlet var backgroundSV: UIScrollView!
    
    
    var recepie : [Recepie] = []
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissTap))
        view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notifcation:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        v60Bottun.backgroundColor = UIColor.systemBrown
        v60Bottun.layer.cornerRadius = 10
        chimixBottun.backgroundColor = UIColor.systemBrown
        chimixBottun.layer.cornerRadius = 10
        calitaBottun.backgroundColor = UIColor.systemBrown
        calitaBottun.layer.cornerRadius = 10
        chimixBottun.layer.borderColor = CGColor(srgbRed: 0.184, green: 0.188, blue: 0.169, alpha: 1)
        calitaBottun.layer.borderColor = CGColor(srgbRed: 0.184, green: 0.188, blue: 0.169, alpha: 1)
        v60Bottun.layer.borderColor = CGColor(srgbRed: 0.184, green: 0.188, blue: 0.169, alpha: 1)
        toolTitel.text = "   Tool".localized
        grainTitel.text = "   Grain".localized
        tempTitel.text = "   Temperature".localized
        roasteryTitel.text = "   Roastery".localized
        ratioTitel.text = "   Ratio".localized
        prepareTitel.text = "   Preparation".localized
        addBottun.setTitle("Add New".localized, for: .normal)
        moreTools.placeholder = "Another".localized
        tfGrain.placeholder = "   Grind".localized
        tFTemp.placeholder = "   Select C".localized
        tfRatio.placeholder = "   Ratio".localized
        tfRoastery.placeholder = "   Roastery".localized
        
        
        
        
        
        
        
        
    }
    
    
    
    
    func CreateData(tool: String,grain: String,roastery: String, prepartion: String,temp:String,ratio:String){
        let newRecepie = Recepie(context: context)
        newRecepie.grain = grain
        newRecepie.tools = tool
        newRecepie.prepare = prepartion
        newRecepie.roastery = roastery
        newRecepie.temp = temp
        newRecepie.ratio = ratio
        
        saveData()
    }
    func saveData(){
        // save to DB
        do {// save function throws error so we have to use try catch
            try context.save()
            print("saved")
        } catch {
            print("Unable to save")
        }
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
    
    @IBAction func addNew(_ sender: Any) {
        
        if moreTools.text?.isEmpty == true || tfGrain.text?.isEmpty == true ||
            tfRoastery.text?.isEmpty == true ||
            tVPrepare.text.isEmpty == true ||
            tFTemp.text?.isEmpty == true || tfRatio.text?.isEmpty == true {
            
            let alert = UIAlertController(title: "thire is wrong ", message: "Empety Fields ", preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
            alert.addAction(ok)
            present(alert, animated: true, completion: nil)
        }else{
            
            
            
            if let tool = moreTools.text, let grain = tfGrain.text , let tempr = tFTemp.text, let prepation = tVPrepare.text, let roastery = tfRoastery.text, let ratio = tfRatio.text  {
                CreateData(tool: tool, grain: grain, roastery: roastery, prepartion: prepation, temp: tempr ,ratio: ratio)
                recepie = getData()
            }
            
            self.delegate?.didFinishUpdates(finished: true)
            dismiss(animated: true){
                
                
            }
        }
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
    
    @objc func keyboardWillShow(notifcation:NSNotification){
        
        if let scrollView = backgroundSV, let userInfo = notifcation.userInfo, let endValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey], let durationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey], let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] {
            
            // Transform the keyboard's frame into our view's coordinate system
            let endRect = view.convert((endValue as AnyObject).cgRectValue, from: view.window)
            
            // Find out how much the keyboard overlaps our scroll view
            let keyboardOverlap = scrollView.frame.maxY - endRect.origin.y
            
            // Set the scroll view's content inset & scroll indicator to avoid the keyboard
            scrollView.contentInset.bottom = keyboardOverlap
            //                   scrollView.scrollIndicatorInsets.bottom = keyboardOverlap
            
            let duration = (durationValue as AnyObject).doubleValue
            let options = UIView.AnimationOptions(rawValue: UInt((curveValue as AnyObject).integerValue << 16))
            UIView.animate(withDuration: duration!, delay: 0, options: options, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    
    
    @IBAction func v60Btn(_ sender: UIButton) {
        //        let empety = UIColor.systemBrown
        //        let full = UIColor.systemBrown
        //        if v60Bottun.backgroundColor == UIColor(named: "Color-2") {
        //            v60Bottun.backgroundColor = full
        //            self.isv60 = true
        moreTools.text = "V60"
        //        }else{
        //            v60Bottun.backgroundColor = empety
        //            self.isv60 = false
        //
        //        }
    }
    
    
    @IBAction func chimixBtn(_ sender: Any) {
        //        let empety = UIColor(named:"Color-2" )
        //        let full = UIColor.systemBrown
        //        if chimixBottun.backgroundColor == UIColor(named: "Color-2") {
        //            chimixBottun.backgroundColor = full
        //            self.isChimix = true
        moreTools.text = "Chimix"
        //        }else{
        //            chimixBottun.backgroundColor = empety
        //            self.isChimix = false
        //
        //        }
    }
    
    
    @IBAction func calitaBtn(_ sender: Any) {
        //        let empety = UIColor(named:"Color-2" )
        //        let full = UIColor.systemBrown
        //        if calitaBottun.backgroundColor == UIColor(named: "Color-2") {
        //            calitaBottun.backgroundColor = full
        //            self.isCalita = true
        moreTools.text = "Kalita"
        //        }else{
        //            calitaBottun.backgroundColor = empety
        //            self.isCalita = false
        //
        //        }
    }
    
    
    
    
    
    
}
