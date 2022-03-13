//
//  StepsTimer.swift
//  Waznah
//
//  Created by Anas Hamad on 07/08/1443 AH.
//

import UIKit

let screenWidth = UIScreen.main.bounds.size.width
class StepsTimer: UIViewController {
    
    
    
    
    
    let lessonLabel : UILabel = {
        let label = UILabel()
        label.text = "Hello".localized
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.textColor = UIColor.white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
        
    }()
    let secondLessonLabel : UILabel = {
        let label = UILabel()
        label.text = "Ready for make a coffee ?".localized
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textColor = UIColor.gray
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
        
    }()
    let fourthLessonLabel : UILabel = {
        let label = UILabel()
        label.text = "*This for One cup of coffee and 18 Gram".localized
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.white.withAlphaComponent(0.4)
        label.numberOfLines = 3
        label.layer.cornerRadius = 12
        label.shadowColor = UIColor.gray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        return label
        
    }()
    let thirdLessonLabel : UILabel = {
        let label = UILabel()
        label.text = "get ready".localized
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textColor = UIColor.gray
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
        
    }()
    
    let timeLabel : UILabel = {
        let label = UILabel()
        label.text = "1"
        label.font = UIFont.boldSystemFont(ofSize: 40)
        label.textColor = UIColor.white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
        
    }()
    
    let startBtn :UIButton = {
        let bottun = UIButton()
        bottun.setTitle("START".localized, for: .normal)
        bottun.layer.cornerRadius = 12
        bottun.backgroundColor = UIColor.black
        bottun.translatesAutoresizingMaskIntoConstraints = false
        
        return bottun
    }()
    let puseBtn :UIButton = {
        let bottun = UIButton()
        bottun.setTitle("Puase".localized, for: .normal)
        bottun.layer.cornerRadius = 12
        bottun.backgroundColor = UIColor.black
        bottun.translatesAutoresizingMaskIntoConstraints = false
        
        return bottun
    }()
    let shapeView : UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "bar")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    let cupView : UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "cup")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.alpha = 0.4
        return imageView
    }()
    let backGraundView : UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "backGraound")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.alpha = 1
        return imageView
    }()
    
    
    let tableView = UITableView()
    var timer = Timer()
    let shapeLayer = CAShapeLayer()
    var durationTimer :CFTimeInterval = 180
    var isRanning = false
    
    var startTime: CFTimeInterval!
    var timer2 = Timer()
    weak var displayLink: CADisplayLink?
    let whaterWave = WaterWave()
    var doration : CGFloat = 0.0
    var elepsed : CGFloat = 0.0
    
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.animationCyrcle()
        
        view.addSubview(backGraundView)
        backGraundView.frame = view.bounds
        view.sendSubviewToBack(backGraundView)
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.whaterWave.setupProgress(self.whaterWave.prograss)
        
        let time = secondToMenutisToSecond(second: Int(durationTimer))
        let timeString = makeStringTimer(minutes: time.0,
                                         second: time.1)
        timeLabel.text = timeString
        constrants()
        
        startBtn.addTarget(self, action: #selector(startBtnTapped), for: .touchUpInside)
        
        doration = CGFloat(1.0 / (durationTimer / 0.01))
        elepsed = CGFloat( -1)
        
        
    }
    @IBAction func closeBtn(_ sender: Any) {
        dismiss(animated: true)
    }
    
    
    func animationWater(Duration:CFTimeInterval){
        
        
        
        if !timer2.isValid {
            
            timer2 = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { _ in
                
                (self.whaterWave.prograss += self.doration )
                
                print(self.doration)
                
                
                self.whaterWave.setupProgress(self.whaterWave.prograss)
                
                if self.whaterWave.prograss >= 1  {
                    self.timer2.invalidate()
                }
                
            })
            
        }
    }
    
    
    @objc func startBtnTapped(){
        if (isRanning){
            
            guard isRanning,let presentation = shapeLayer.presentation() else {return }
            
            isRanning = false
            startBtn.setTitle("start", for: .normal)
            startBtn.setTitleColor(UIColor.white, for: .normal)
            timer.invalidate()
            
            shapeLayer.strokeStart = presentation.strokeStart
            shapeLayer.removeAnimation(forKey: "basicAnimation")
            whaterWave.layer.removeAnimation(forKey: "transform.translation.x")
            whaterWave.layer.removeAnimation(forKey: "opacity")
            timer2.invalidate()
            
            
        }else {
            
            isRanning = true
            startBtn.setTitle("Puase".localized, for: .normal)
            startBtn.setTitleColor(UIColor.systemPink, for: .normal)
            DispatchQueue.main.async { [self] in
                
                
                self.BaisecAnimation()
                
                self.animationWater(Duration: self.durationTimer)
                
                if !self.timer.isValid{
                    timer  = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerAction), userInfo: nil, repeats: true)
                }else{
                    timer.invalidate()
                }
                
            }
            
            
        }
        
        
    }
    
    
    @objc func timerAction(){
        durationTimer += elepsed
        
        
        let time = secondToMenutisToSecond(second: Int(durationTimer))
        let timeString = makeStringTimer(minutes: time.0,
                                         second: time.1)
        timeLabel.text = timeString
        
        
        
        switch durationTimer{
        case 179 :
            
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            secondLessonLabel.text = "get ready".localized
            lessonLabel.text = "pour 40 ml of water".localized
            thirdLessonLabel.text = "pour 80 ml and wait to drain".localized
            
            
        case 140 :
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            secondLessonLabel.text = "pour 40 ml of water".localized
            lessonLabel.text = "pour 80 ml and wait to drain".localized
            thirdLessonLabel.text = "pour 90 ml and wait".localized
            
        case 115:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            secondLessonLabel.text = "pour 80 ml and wait to drain".localized
            lessonLabel.text = "pour 90 ml and wait".localized
            thirdLessonLabel.text = "pour 90 ml and wait".localized
            
        case 65 :
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            secondLessonLabel.text = "pour 90 ml and wait".localized
            lessonLabel.text = "pour 90 ml and wait".localized
            thirdLessonLabel.text = "wait to drain all coffee".localized
            
        case 35 :
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            secondLessonLabel.text = "pour 90 ml and wait".localized
            lessonLabel.text = "wait to drain all coffee".localized
            thirdLessonLabel.text = "done!".localized
            
        case 0 :
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            timer.invalidate()
            startBtn.isHidden = true
            lessonLabel.text = "done!".localized
            
        default:
            0
        }
        
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
    
    // MARK: Animations
    
    
    func animationCyrcle() {
        
        let center = CGPoint(x: shapeView.frame.width / 2, y: shapeView.frame.height / 2)
        let endAngle = (-CGFloat.pi / 2)
        let startAngle = 2 * CGFloat.pi + endAngle
        let redus = (shapeView.frame.width / 2) - 15
        
        let cercularPath = UIBezierPath(arcCenter: center, radius: redus, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        
        shapeLayer.path = cercularPath.cgPath
        shapeLayer.lineWidth = 21
        shapeLayer.fillColor =  UIColor.clear.cgColor
        shapeLayer.strokeEnd = 1
        shapeLayer.lineCap = CAShapeLayerLineCap.round
        shapeLayer.strokeColor = #colorLiteral(red: 0.09603477269, green: 0.02015891671, blue: 0.1063941196, alpha: 1)
        shapeView.layer.addSublayer(shapeLayer)
        
    }
    
    func BaisecAnimation(){
        
        let baisicAnimatios = CABasicAnimation(keyPath: "strokeEnd")
        
        baisicAnimatios.toValue = 0
        baisicAnimatios.isRemovedOnCompletion = false
        baisicAnimatios.duration = CFTimeInterval(durationTimer)
        baisicAnimatios.fillMode = CAMediaTimingFillMode.backwards
        
        shapeLayer.add(baisicAnimatios, forKey: "basicAnimation")
        
    }
}

extension StepsTimer {
    
    func constrants(){
        
        view.addSubview(shapeView)
        NSLayoutConstraint.activate([
            shapeView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shapeView.centerYAnchor.constraint(equalTo: view.centerYAnchor,constant: -180),
            shapeView.heightAnchor.constraint(equalToConstant: screenWidth * 0.8),
            shapeView.widthAnchor.constraint(equalToConstant: screenWidth * 0.8)
            
        ])
        
        shapeView.addSubview(timeLabel)
        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: shapeView.bottomAnchor, constant: 8),
            timeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            timeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
            
        ])
        
        view.addSubview(startBtn)
        NSLayoutConstraint.activate([
            startBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60),
            startBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startBtn.heightAnchor.constraint(equalToConstant: 70),
            startBtn.widthAnchor.constraint(equalToConstant: 100)
            
        ])
        
        view.addSubview(whaterWave)
        NSLayoutConstraint.activate([
            whaterWave.widthAnchor.constraint(equalToConstant: screenWidth * 0.5 ),
            whaterWave.heightAnchor.constraint(equalToConstant: screenWidth * 0.5 ),
            whaterWave.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            whaterWave.centerYAnchor.constraint(equalTo: view.centerYAnchor,constant: -180)
            
        ])
        
        whaterWave.addSubview(cupView)
        NSLayoutConstraint.activate([
            cupView.widthAnchor.constraint(equalToConstant: screenWidth * 0.5 ),
            cupView.heightAnchor.constraint(equalToConstant: screenWidth * 0.5 ),
            cupView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cupView.centerYAnchor.constraint(equalTo: view.centerYAnchor,constant: -180)
            
        ])
        
        view.addSubview(secondLessonLabel)
        NSLayoutConstraint.activate([
            secondLessonLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            secondLessonLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor,constant: 5)
            
            
        ])
        
        view.addSubview(lessonLabel)
        NSLayoutConstraint.activate([
            lessonLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            lessonLabel.topAnchor.constraint(equalTo: secondLessonLabel.bottomAnchor,constant: 8)
            
            
        ])
        
        view.addSubview(thirdLessonLabel)
        NSLayoutConstraint.activate([
            thirdLessonLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            thirdLessonLabel.topAnchor.constraint(equalTo: lessonLabel.bottomAnchor,constant: 8)
            
        ])
        
        view.addSubview(fourthLessonLabel)
        NSLayoutConstraint.activate([
            fourthLessonLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            fourthLessonLabel.bottomAnchor.constraint(equalTo: startBtn.topAnchor,constant: -10),
            fourthLessonLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            fourthLessonLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
            
        ])
        
    }
}





