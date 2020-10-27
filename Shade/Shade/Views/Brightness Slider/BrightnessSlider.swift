//
//  FatUISlider.swift
//  Shade
//
//  Created by Charlie While on 26/10/2020.
//

import UIKit

class BrightnessSlider: UISlider {
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var customBounds = super.trackRect(forBounds: bounds)
        customBounds.size.height = 15
        return customBounds
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(tapped(_ :)))
        self.addGestureRecognizer(tapGestureRecogniser)
    }
    
    @objc func tapped(_ gestureRecognizer: UIGestureRecognizer) {
        let pointTapped = gestureRecognizer.location(in: gestureRecognizer.view)
        let pointOfSlider = self.frame.origin
        let newValue = ((pointTapped.x - pointOfSlider.x) * CGFloat(self.maximumValue)) / self.frame.width
        
        self.setValue(Float(newValue), animated: true)
        NotificationCenter.default.post(name: .BrightnessChanged, object: nil)
    }
    
}
