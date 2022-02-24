//
//  ViewController.swift
//  Waznah
//
//  Created by Anas Hamad on 16/06/1443 AH.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var grTextF: UITextField!
    @IBOutlet var mlTextF: UITextField!
    @IBOutlet var ratioTF: UITextField!
    @IBOutlet var startBtn: UIButton!
    @IBOutlet var resetBtn: UIButton!
    @IBOutlet var timerLabel: UILabel!
    @IBOutlet var recipesBtn: UIButton!
    
    
    var timer:Timer = Timer()
    var count : Int = 0
    var timerCounting : Bool = false
    
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationConfigure()
        mlTextF.addTarget(self, action: #selector(tabMlText(_:)), for: .touchDown)
        grTextF.addTarget(self, action: #selector(tabGrText(_:)), for: .touchDown)
        startBtn.setTitleColor(UIColor.green, for: .normal)
        resetBtn.layer.cornerRadius = 12
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissTap))
        view.addGestureRecognizer(tap)
        
        recipesBtn.setTitleColor(UIColor.systemBrown, for: .normal)
        recipesBtn.backgroundColor = .quaternarySystemFill
        resetBtn.layer.cornerRadius = 8
        startBtn.setTitleColor(UIColor.black, for: .normal)
        resetBtn.setTitleColor(UIColor.black, for: .normal)
        
      
    }
    
  
    
    private func navigationConfigure(){
        navigationController?.navigationBar.backIndicatorImage = UIImage(systemName: "arrow.backward")
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(systemName: "arrow.backward")
        navigationController?.navigationBar.tintColor = .black
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    @objc func tabMlText(_ sender: Any) {
        var textFMl = UITextField()
        textFMl.reloadInputViews()
        let alert = UIAlertController(title: "Select Gr", message: "Change Gr", preferredStyle: .alert)
        alert.addTextField { textInputMode in
            textInputMode.placeholder = "gr."
            textFMl = textInputMode
        }
        let ok = UIAlertAction(title: "Ok", style: .default) { alet in
            self.mlTextF.text = textFMl.text
            guard let firstNumberConv :Double = Double(self.mlTextF.text!) else {return}
            guard let secondNumberConv :Double = Double(self.ratioTF.text!) else {return}
            
            
            self.grTextF.text = "\(firstNumberConv * secondNumberConv)"
            
        }
        alert.addAction(ok)
        
        present(alert, animated: true, completion: nil)
        
    }
    
    @objc func tabGrText (_ sender: Any ) {
        
        var textFMl = UITextField()
        textFMl.reloadInputViews()
        let alert = UIAlertController(title: "Select ML", message: "Change ML", preferredStyle: .alert)
        alert.addTextField { textInputMode in
            textInputMode.placeholder = "ml."
            textFMl = textInputMode
        }
        
        let ok = UIAlertAction(title: "Ok", style: .default) { alet in
            self.grTextF.text = textFMl.text
            guard let firstNumberConv :Double = Double(self.grTextF.text!) else {return}
            guard let secondNumberConv :Double = Double(self.ratioTF.text!) else {return}
            self.mlTextF.text = "\(firstNumberConv / secondNumberConv)"
        }
        
        alert.addAction(ok)
        
        present(alert, animated: true, completion: nil)
        
    }
    
    
    @IBAction func startBtnAcction(_ sender: Any) {
        
        if (timerCounting)
        {
            timerCounting = false
            timer.invalidate()
            startBtn.setTitle("START", for: .normal)
            startBtn.setTitleColor(UIColor.black, for: .normal)
        }
        else
        {
            timerCounting = true
            timer.invalidate()
            startBtn.setTitle("Puase", for: .normal)
            startBtn.setTitleColor(UIColor.red, for: .normal)
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerCounter), userInfo: nil, repeats: true)
        }
    }
    
    
    @IBAction func resetBtnAction(_ sender: Any) {
       
        count = 0
        timer.invalidate()
        timerLabel.text = self.makeStringTimer(hours: 0, minutes: 0, second: 0)
        startBtn.setTitle("START", for: .normal)
        startBtn.setTitleColor(UIColor.black, for: .normal)
    }
    
    
    
    @objc func timerCounter() -> Void {
        
        count = count + 1
        let time = secondToMenutisToSecond(second: count)
        let timeString = makeStringTimer(hours: time.0, minutes: time.1, second: time.2)
        timerLabel.text = timeString
        
    }
    
    func secondToMenutisToSecond (second:Int) -> (Int,Int,Int){
        
        return ((second / 3600 ), ((second % 3600) / 60), ((second % 3600 ) % 60))
        
    }
    
    func makeStringTimer (hours:Int,minutes:Int,second:Int) -> String{
        
        var timeString = ""
        timeString += String(format: "%02d", hours)
        timeString += ":"
        timeString += String(format: "%02d", minutes)
        timeString += ":"
        timeString += String(format: "%02d", second)
        
        
        return timeString
        
        
    }
    
    
    @IBAction func recepiActions(_ sender: Any) {
        
        performSegue(withIdentifier: "recipes", sender: self)
        
        
    }
    @objc func dismissTap() {
        mlTextF.resignFirstResponder()
        grTextF.resignFirstResponder()
        ratioTF.resignFirstResponder()
    }
    
}


