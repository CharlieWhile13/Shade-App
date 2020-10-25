//
//  AnimatingColourView.swift
//  Shade
//
//  Created by Charlie While on 24/10/2020.
//

import UIKit

class DynamicColourView: UIView {
    
    @IBInspectable private var enableRandomColour: Bool = false
    
    var gradientLayer: CAGradientLayer!
    
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
                
        if !UIAccessibility.isReduceTransparencyEnabled {
            let blurEffect = UIBlurEffect(style: .extraLight)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)

            blurEffectView.frame = self.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            self.addSubview(blurEffectView)
        }
    }
    
    public func setup() {
        self.gradientLayer = CAGradientLayer(start: .topLeft, end: .bottomRight, colors: [randomColour().cgColor, randomColour().cgColor], type: .radial)
        self.gradientLayer.frame = self.bounds
        self.layer.addSublayer(self.gradientLayer)
        
        if enableRandomColour {
            self.randomColours()
        }
    }

    private func randomColours() {
        let toColours = [randomColour().cgColor, randomColour().cgColor]
      
        let colourAnimation = CABasicAnimation(keyPath: "colors")
        colourAnimation.fromValue = self.gradientLayer.colors
        colourAnimation.toValue = toColours
        colourAnimation.duration = 3.0
        colourAnimation.isRemovedOnCompletion = true
        colourAnimation.delegate = self
     
        self.gradientLayer.colors = toColours
        self.gradientLayer.add(colourAnimation, forKey: nil)
    }
}

extension DynamicColourView: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let animation = anim as? CABasicAnimation {
            
            switch animation.keyPath {
                case "colors" : self.randomColours()
                default : return
            }

        }
    }
}

