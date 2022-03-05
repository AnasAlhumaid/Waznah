//
//  BrewSteps.swift
//  Waznah
//
//  Created by Anas Hamad on 01/08/1443 AH.
//

import UIKit

@IBDesignable
public class CircularProgressView: UIView {

    @IBInspectable var duration:  CFTimeInterval = 10
    @IBInspectable var lineWidth: CGFloat = 1  { didSet { updatePaths() } }

    private(set)   var isRunning = false
    private        var elapsed: CFTimeInterval = 0
    private        var startTime: CFTimeInterval!
    private        let animationKey = Bundle.main.bundleIdentifier! + ".strokeEnd"

    private let backgroundShapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1).cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        return shapeLayer
    }()
    
    private let progressShapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = #colorLiteral(red: 0.2319213939, green: 0.5, blue: 0.224438305, alpha: 1).cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = .round
        shapeLayer.strokeEnd = 0
        return shapeLayer
    }()
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updatePaths()
    }
    
    public override func prepareForInterfaceBuilder() {
        progressShapeLayer.strokeEnd = 1 / 3
    }
}

// MARK: - Public interface

public extension CircularProgressView {
    func start(duration: CFTimeInterval) {
        self.duration = duration
        reset()
        resume()
    }
    
    func pause() {
        guard
            isRunning,
            let presentation = progressShapeLayer.presentation()
        else {
            return
        }
        
        elapsed += CACurrentMediaTime() - startTime
        progressShapeLayer.strokeEnd = presentation.strokeEnd
        progressShapeLayer.removeAnimation(forKey: animationKey)
    }
    
    func resume() {
        guard !isRunning else { return }
        
        isRunning = true
        startTime = CACurrentMediaTime()
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = elapsed / duration
        animation.toValue = 1
        animation.duration = duration - elapsed
        animation.delegate = self
        progressShapeLayer.strokeEnd = 1
        progressShapeLayer.add(animation, forKey: animationKey)
    }
    
    func reset() {
        isRunning = false
        progressShapeLayer.removeAnimation(forKey: animationKey)
        progressShapeLayer.strokeEnd = 0
        elapsed = 0
    }
}

extension CircularProgressView: CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        isRunning = false
    }
}

// MARK: - Utility

private extension CircularProgressView {
    func configure() {
        layer.addSublayer(backgroundShapeLayer)
        layer.addSublayer(progressShapeLayer)
    }
    
    func updatePaths() {
        let radius = (min(bounds.width, bounds.height) - lineWidth) / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: -.pi / 2, endAngle: 3 * .pi / 2, clockwise: true)
        
        backgroundShapeLayer.lineWidth = lineWidth
        progressShapeLayer.lineWidth = lineWidth
        
        backgroundShapeLayer.path = path.cgPath
        progressShapeLayer.path = path.cgPath
    }
}
