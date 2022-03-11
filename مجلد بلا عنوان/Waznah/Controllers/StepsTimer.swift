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
            label.text = "Hello"
            label.font = UIFont.boldSystemFont(ofSize: 30)
            label.textColor = UIColor.white
            label.numberOfLines = 0
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
            
        }()
        let secondLessonLabel : UILabel = {
            let label = UILabel()
            label.text = "Hello"
            label.font = UIFont.boldSystemFont(ofSize: 24)
            label.textColor = UIColor.gray
            label.numberOfLines = 0
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
            
        }()
        let thirdLessonLabel : UILabel = {
            let label = UILabel()
            label.text = "Hello"
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
            bottun.setTitle("start", for: .normal)
            bottun.layer.cornerRadius = 12
            bottun.backgroundColor = UIColor.black
            bottun.translatesAutoresizingMaskIntoConstraints = false
            
            return bottun
        }()
        let puseBtn :UIButton = {
            let bottun = UIButton()
            bottun.setTitle("puse", for: .normal)
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
        var steps = ["1","2","3","4"]
        var step = [String]()
        
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            self.animationCyrcle()
            
            view.addSubview(backGraundView)
            backGraundView.frame = view.bounds
            view.sendSubviewToBack(backGraundView)
            
        }
        
        
        
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            
            
            
            tableView.delegate = self
            tableView.dataSource = self
            tableView.translatesAutoresizingMaskIntoConstraints = false
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
            tableView.backgroundColor = .clear
            
            whaterWave.setupProgress(self.whaterWave.prograss)
            
            
            
            
            let time = secondToMenutisToSecond(second: Int(durationTimer))
            let timeString = makeStringTimer(minutes: time.0,
                                             second: time.1)
            timeLabel.text = timeString
            constrants()
            
            
            startBtn.addTarget(self, action: #selector(startBtnTapped), for: .touchUpInside)
            
            doration = CGFloat(1.0 / (durationTimer / 0.01))
            elepsed = CGFloat(durationTimer - 1)
            
            
        }
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            
            
            
            
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
                startBtn.setTitle("pause", for: .normal)
                startBtn.setTitleColor(UIColor.systemPink, for: .normal)
                animationWater(Duration: durationTimer)
                
                    BaisecAnimation()
               
                
                if !self.timer.isValid{
                    timer  = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerAction), userInfo: nil, repeats: true)
                }else{
                    timer.invalidate()
                }
                }
                
            
        }
        
        
        @objc func timerAction(){
            durationTimer -= 1
            
            
            let time = secondToMenutisToSecond(second: Int(durationTimer))
            let timeString = makeStringTimer(minutes: time.0,
                                             second: time.1)
            timeLabel.text = timeString
           
            switch durationTimer{
            case 179 :

                UINotificationFeedbackGenerator().notificationOccurred(.success)

//                step.insert("pure 40 ml and wait to blooming", at: 0)
//                tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                

                
            case 140 :
                UINotificationFeedbackGenerator().notificationOccurred(.success)

                step.insert("pure 80 ml and wait to drain ", at: 0)
                tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)


            case 115:
                UINotificationFeedbackGenerator().notificationOccurred(.success)

                step.insert("pure 90 ml and wait ", at: 0)
                tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)


            case 65 :
                UINotificationFeedbackGenerator().notificationOccurred(.success)

                step.insert("pure 90 ml and wait ", at: 0)
                tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)


            case 35 :
                UINotificationFeedbackGenerator().notificationOccurred(.success)

                step.insert("wait to drain all coffee", at: 0)
                tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)



            case 0 :
                UINotificationFeedbackGenerator().notificationOccurred(.success)

                timer.invalidate()
                startBtn.isHidden = true
                lessonLabel.text = "done!"

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
                startBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80),
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
            
            view.addSubview(tableView)
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor,constant: 8),
                tableView.bottomAnchor.constraint(equalTo: startBtn.topAnchor,constant: 8),
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                
            ])
            
        }
    }


    extension StepsTimer : UITableViewDelegate, UITableViewDataSource {
        
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return steps.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            
            
                cell.textLabel?.text = steps[indexPath.row]
                cell.textLabel?.textAlignment = .center
                cell.backgroundColor = UIColor.clear
                
                if (indexPath.row == 0 ){
                    cell.textLabel?.textColor = .black
                }else{
                    cell.textLabel?.textColor = .white
                }
            
         
         
            
            
            return cell
        }
       
        
    }


