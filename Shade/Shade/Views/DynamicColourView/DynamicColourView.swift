//
//  AnimatingColourView.swift
//  Shade
//
//  Created by Charlie While on 24/10/2020.
//

import UIKit

class DynamicColourView: UIView {
    
    @IBInspectable private var random: Bool = false
    
    var gradientLayer: CAGradientLayer?
    var setColours: [CGColor]!
    
    private func randomColour() -> UIColor {
        let red = CGFloat((arc4random() % 256)) / 255.0
        let green = CGFloat((arc4random() % 256)) / 255.0
        let blue = CGFloat((arc4random() % 256)) / 255.0
        let alpha = CGFloat(1.0)
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    private func addOneForPoint(_ point: CGFloat) -> CGFloat {
        var point = point + 0.1
        if point > 1.0 { point = 0.0 }
        return point
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        setupAnimations()
    }
    
    private func setupAnimations() {
        self.setColours = [randomColour().cgColor, randomColour().cgColor]
        self.gradientLayer = CAGradientLayer(start: .topLeft, end: .bottomRight, colors: self.setColours, type: .radial)
        self.gradientLayer?.frame = self.bounds
        
        if self.gradientLayer != nil {
            self.layer.addSublayer(self.gradientLayer!)
            self.animateChange()
        }
    }
    
    @objc private func rotateController() {
        UIView.animate(withDuration: 3, delay: 0, options: [.autoreverse, .repeat], animations: {
            if self.gradientLayer != nil {
                /*
                let originalStart = self.gradientLayer!.startPoint
                let originalEnd = self.gradientLayer!.endPoint
                
                let newStartX = self.addOneForPoint(originalStart.x)
                let newEndX = self.addOneForPoint(originalEnd.x)
                
                let newStartY = self.addOneForPoint(originalStart.y)
                let newEndY = self.addOneForPoint(originalEnd.y)
                
                let newStartPoint = CGPoint(x: newStartX, y: newStartY)
                let newEndPoint = CGPoint(x: newEndX, y: newEndY)
                */
                
                let newColours = [self.randomColour().cgColor, self.randomColour().cgColor]
                
                self.gradientLayer!.colors = newColours
                //self.gradientLayer!.startPoint = newStartPoint
                //self.gradientLayer!.endPoint = newEndPoint
            }
        }, completion: nil)
    }
    
    private func animateChange() {
        print("This is running like a boss")
        if self.gradientLayer != nil {
            let animation = CABasicAnimation(keyPath: "colors")
            animation.fromValue = self.setColours
            self.setColours = [randomColour().cgColor, randomColour().cgColor]
            animation.toValue = self.setColours
            animation.duration = 5.0
            animation.isRemovedOnCompletion = true
            animation.delegate = self
            
            self.gradientLayer!.add(animation, forKey: nil)
        }
    }
}

extension DynamicColourView: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.gradientLayer!.colors = setColours
        self.animateChange()
    }
}
