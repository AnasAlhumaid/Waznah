//
//  WhaterWave.swift
//  Waznah
//
//  Created by Anas Hamad on 07/08/1443 AH.
//

import Foundation
import UIKit


class WaterWave : UIView{
    
    //MARK: propetes
    private let firstLayer = CAShapeLayer()
    private let secondLayer = CAShapeLayer()
    
    private var firstColor :UIColor = .clear
    private var secondColor :UIColor = .clear
    
    private let towr : CGFloat = .pi*2
    private var offset : CGFloat = 0.0
    
    private let width = screenWidth*0.5
    
    private let presentageLabel = UILabel()
    
    var showSingleWave = false
    private var start = false
    
    var prograss : CGFloat = 0.0
    var waveHeight : CGFloat = 0.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
}

extension WaterWave {
    
    func setupViews(){
        bounds = CGRect(x: 0.0, y: 0.0, width:min(width, width), height: min(width, width))
       clipsToBounds = true
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        
        layer.cornerRadius = width / 2
        layer.masksToBounds = true
        layer.borderWidth = 1.0
        layer.borderColor = #colorLiteral(red: 0.2792488635, green: 0.2254267037, blue: 0.2047516108, alpha: 1)
        
        
        waveHeight = 8.0
        firstColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        secondColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).withAlphaComponent(0.4)
        
        createFirestLayer()
        
        if !showSingleWave{
            createSecondLayer()
        }
        
//        createPrecentLabel()
    }
    
    private func createFirestLayer(){
        firstLayer.frame = bounds
        firstLayer.anchorPoint = .zero
        firstLayer.fillColor = firstColor.cgColor
        layer.addSublayer(firstLayer)
        
    }
    
    private func createPrecentLabel(){
        
        presentageLabel.font = UIFont.boldSystemFont(ofSize: 35.0)
        presentageLabel.textAlignment = .center
        presentageLabel.text = ""
        presentageLabel.textColor = .darkGray
        addSubview(presentageLabel)
        presentageLabel.translatesAutoresizingMaskIntoConstraints = false
        presentageLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = false
        presentageLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = false
        
        
    }
    
    private func createSecondLayer(){
        secondLayer.frame = bounds
        secondLayer.anchorPoint = .zero
        secondLayer.fillColor = secondColor.cgColor
        layer.addSublayer(secondLayer)
        
        
    }
    
    func presentLabel(){
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.duration = 0.2
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        
        presentageLabel.layer.add(animation, forKey: nil)
    }
    
   func setupProgress(_ pr: CGFloat){
        prograss = pr

        let top :CGFloat =   pr * bounds.size.height
       firstLayer.setValue(width - top, forKeyPath: "position.y")
        secondLayer.setValue(width - top, forKeyPath: "position.y")
        
        if !start {
            DispatchQueue.main.async {
                self.startAnimatio()
            }
        }
    }
    
    private func startAnimatio(){
        
        start = true
        WaterWaveAnimation()
    }
    
    private func WaterWaveAnimation(){
        let w = bounds.size.width
        let h = bounds.size.height
        
        let bizer = UIBezierPath()
        let path = CGMutablePath()
        
        
        let startOfsetY = waveHeight * CGFloat(sinf(Float(offset * towr / w)))
        var originOfset :CGFloat = 0.0
        
        
        path.move(to: CGPoint(x: 0.0, y: startOfsetY), transform: .identity)
        bizer.move(to: CGPoint(x: 0.0, y: startOfsetY))
        
        
        for i in stride(from: 0.0, to: w*1000, by: 1){
            
            originOfset = waveHeight * CGFloat(sinf(Float(towr / w * i + offset * towr / w )))
            bizer.addLine(to: CGPoint(x: i, y: originOfset))
            
            
        }
        
        bizer.addLine(to: CGPoint(x: w*1000, y: originOfset))
        bizer.addLine(to: CGPoint(x: w*1000, y: h))
        bizer.addLine(to: CGPoint(x: 0.0, y: h))
        bizer.addLine(to: CGPoint(x: 0.0, y: startOfsetY))
        bizer.close()
        
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.duration = 2.0
        animation.fromValue = -(w * 0.5)
        animation.toValue = (-w) - (w * 0.5)
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        
        
        
        
        firstLayer.fillColor = firstColor.cgColor
        firstLayer.path = bizer.cgPath
        firstLayer.add(animation, forKey: nil)
        
        
//        if !showSingleWave {
//            let bizer = UIBezierPath()
//
//
//            let startOfsetY = waveHeight * CGFloat(sinf(Float(offset * towr / w)))
//            var originOfset :CGFloat = 0.0
//
//
//            bizer.move(to: CGPoint(x: 0.0, y: startOfsetY))
//
//
//            for i in stride(from: 0.0, to: w*1000, by: 1){
//
//                originOfset = waveHeight * CGFloat(cosf(Float(towr / w * i + offset * towr / w )))
//                bizer.addLine(to: CGPoint(x: i, y: originOfset))
//
//
//            }
//
//            bizer.addLine(to: CGPoint(x: w*1000, y: originOfset))
//            bizer.addLine(to: CGPoint(x: w*1000, y: h))
//            bizer.addLine(to: CGPoint(x: 0.0, y: h))
//            bizer.addLine(to: CGPoint(x: 0.0, y: startOfsetY))
//            bizer.close()
//
//
//
//            secondLayer.fillColor = secondColor.cgColor
//            secondLayer.path = bizer.cgPath
//            secondLayer.add(animation, forKey: nil)
//        }
//
//    }
    
    
    
    
    
    
}
}
