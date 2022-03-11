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
    @IBOutlet var timerTitel: UILabel!
    
    
    var timer:Timer = Timer()
    var count : Int = 0
    var timerCounting : Bool = false
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationConfigure()
        uiViewStyle()
        
        mlTextF.addTarget(self,
                          action: #selector(tabMlText(_:)),
                          for: .touchDown)
        
        grTextF.addTarget(self,
                          action: #selector(tabGrText(_:)),
                          for: .touchDown)

        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(dismissTap))
        
        view.addGestureRecognizer(tap)
        
        startBtn.setTitle("START".localized,
                          for: .normal)
        resetBtn.setTitle("RESET".localized,
                          for: .normal)
        timerTitel.text = "Timer".localized
        
        recipesBtn.setTitle("Recipes".localized,
                            for: .normal)
        ratioTF.keyboardType = .decimalPad
        
    }
    
    func uiViewStyle(){
        
        startBtn.setTitleColor(UIColor.black,
                               for: .normal)
        resetBtn.setTitleColor(UIColor.black,
                               for: .normal)
        recipesBtn.setTitleColor(UIColor.systemBrown, for: .normal)
        recipesBtn.backgroundColor = .quaternarySystemFill
        resetBtn.layer.cornerRadius = 8
        startBtn.setTitleColor(UIColor.green, for: .normal)
        resetBtn.layer.cornerRadius = 12
  
    }
    
    private func navigationConfigure(){
        
        navigationController?.navigationBar.backIndicatorImage = UIImage(systemName: "arrow.backward")
        
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(systemName: "arrow.backward")
        
        navigationController?.navigationBar.tintColor = .black
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "",
                                                           style: .plain,
                                                           target: nil,
                                                           action: nil)
    }
    
    @objc func tabMlText(_ sender: Any) {
        var textFMl = UITextField()
        textFMl.reloadInputViews()
        
        let alert = UIAlertController(title: "Select Gr".localized,
                                      message: "Change Gr".localized,
                                      preferredStyle: .alert)
        
        alert.addTextField { textInputMode in
            textInputMode.placeholder = "gr."
            textFMl = textInputMode
            textInputMode.keyboardType = .decimalPad
            
        }
        
        let ok = UIAlertAction(title: "Ok".localized,
                               style: .default) { alet in
            self.mlTextF.text = textFMl.text
            guard let firstNumberConv :Double = Double(self.mlTextF.text!) else {return}
            guard let secondNumberConv :Double = Double(self.ratioTF.text!) else {return}
            
            
            self.grTextF.text = "\(firstNumberConv * secondNumberConv)"
            
        }
        
        alert.addAction(ok)
        
        present(
            alert,
            animated: true,
            completion: nil)
        
    }
    
    @objc func tabGrText (_ sender: Any ) {
        
        var textFMl = UITextField()
        textFMl.reloadInputViews()
        let alert = UIAlertController(title: "Select ML".localized,
                                      message: "Change ML".localized,
                                      preferredStyle: .alert)
        
        alert.addTextField { textInputMode in
            textInputMode.placeholder = "ml."
            textFMl = textInputMode
            textInputMode.keyboardType = .decimalPad
        }
        
        let ok = UIAlertAction(title: "Ok".localized,
                               style: .default) { alet in
            self.grTextF.text = textFMl.text
            guard let firstNumberConv :Double = Double(self.grTextF.text!) else {return}
            guard let secondNumberConv :Double = Double(self.ratioTF.text!) else {return}
            self.mlTextF.text = "\(firstNumberConv / secondNumberConv)"
        }
        
        alert.addAction(ok)
        
        present(alert,
                animated: true,
                completion: nil)
        
    }
    
    @IBAction func startBtnAcction(_ sender: Any) {
        
        if (timerCounting)
            
        {
            timerCounting = false
            timer.invalidate()
            startBtn.setTitle("START".localized,
                              for: .normal)
            startBtn.setTitleColor(UIColor.black,
                                   for: .normal)
        }
        else
        {
            timerCounting = true
            timer.invalidate()
            startBtn.setTitle("Puase".localized,
                              for: .normal)
            startBtn.setTitleColor(UIColor.red,
                                   for: .normal)
            timer = Timer.scheduledTimer(timeInterval: 1,
                                         target: self,
                                         selector: #selector(timerCounter),
                                         userInfo: nil,
                                         repeats: true)
        }
    }
    
    
    @IBAction func resetBtnAction(_ sender: Any) {
        
        count = 0
        timer.invalidate()
        timerLabel.text = self.makeStringTimer(minutes: 0,
                                               second: 0)
        startBtn.setTitle("START".localized,
                          for: .normal)
        startBtn.setTitleColor(UIColor.black,
                               for: .normal)
    }
    
    @objc func timerCounter() -> Void {
        
        count = count + 1
        let time = secondToMenutisToSecond(second: count)
        let timeString = makeStringTimer(minutes: time.0,
                                         second: time.1)
        timerLabel.text = timeString
        
    }
    
    func secondToMenutisToSecond (second:Int) -> (Int,Int){
        
        return (((second % 3600) / 60),
                ((second % 3600 ) % 60))
        
    }
    
    func makeStringTimer (minutes:Int,second:Int) -> String{
        
        var timeString = ""
      
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


