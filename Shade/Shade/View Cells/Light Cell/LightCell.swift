//
//  LightCell.swift
//  Shade
//
//  Created by Charlie While on 24/10/2020.
//

import UIKit

class LightCell: UICollectionViewCell {

    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func decideTextColour(_ colour: UIColor) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        colour.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        if (red + green + blue) >= 2.7 {
            return .black
        } else {
            return .white
        }
    }

}
