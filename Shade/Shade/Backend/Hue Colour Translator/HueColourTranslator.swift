//
//  HueColourTranslator.swift
//  Shade
//
//  Created by Charlie While on 26/10/2020.
//

import UIKit

class HueColourTranslator {
    static let shared = HueColourTranslator()
    
    public func convertFromColour(_ colour: UIColor) -> (Float, Float) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        colour.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        if red > 0.04045 {
            red = pow((red + 0.055) / (1.0 + 0.055), 2.4)
        } else {
            red = red / 12.92
        }
        
        if green > 0.04045 {
            green = pow((green + 0.055) / (1.0 + 0.055), 2.4)
        } else {
            green = green / 12.92
        }
        
        if blue > 0.04045 {
            blue = pow((blue + 0.055) / (1.0 + 0.55), 2.4)
        } else {
            blue = blue / 12.92
        }
        
        let X: Float = Float(red * 0.664511 + green * 0.154324 + blue * 0.162028)
        let Y: Float = Float(red * 0.283881 + green * 0.668433 + blue * 0.047685)
        let Z: Float = Float(red * 0.000088 + green * 0.072310 + blue * 0.986039)
        
        let x: Float = X / (X + Y + Z)
        let y: Float = Y / (X + Y + Z)
        
        return (x, y)
    }
    
    public func convertFromHue(_ hue: (Float, Float)) {
        
    }
    
}
