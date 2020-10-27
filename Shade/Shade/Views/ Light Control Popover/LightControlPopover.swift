//
//  LightControlPopover.swift
//  Shade
//
//  Created by Charlie While on 26/10/2020.
//

import UIKit

class LightControlPopover: UIView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var lightLabel: UILabel!
    @IBOutlet weak var powerToggle: UIControl!
    @IBOutlet weak var powerImage: UIImageView!
    @IBOutlet weak var brightnessSlider: BrightnessSlider!
    @IBOutlet weak var colourPicker: UIControl!
    @IBOutlet weak var blurView: UIView!
    
    var lightID: String!
    var light: Light!
    var currentBrightness = 0
    var timer: Timer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setup()
    }
    
    override func willMove(toSuperview: UIView?) {
        super.willMove(toSuperview: toSuperview)
        self.parseState()
    }
    
    func setup() {
        if !UIAccessibility.isReduceTransparencyEnabled {
            let blurEffect = UIBlurEffect(style: .dark)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)

            blurEffectView.frame = self.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            self.blurView.addSubview(blurEffectView)
        }
        
        self.powerToggle.addTarget(self, action: #selector(toggleLight), for: .touchUpInside)
        NotificationCenter.default.addObserver(self, selector: #selector(parseState), name: .LightRefactor, object: nil)
    }
    
    @objc func toggleLight() {
        if self.light == nil { return }
        LightManager.shared.toggle(light!)
    }
    
    @objc func setBrightness() {
        let brightnessToSet = self.brightnessSlider.value * 254.0
        let inty = round(brightnessToSet)
        LightManager.shared.setBrightness(self.light, Int(inty))
    }
    
    @objc func parseState() {
        if self.lightID == nil { return }
        self.light = LightManager.shared.lights[LightManager.shared.getIndex(self.lightID)]
        let state = self.light!.state!
        let colour = HueColourTranslator.shared.convertFromHue(state)
        
        if !state.on! {
            self.imageView.image = UIImage(systemName: "lightbulb.slash.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))?.withTintColor(.systemGray5, renderingMode: .alwaysOriginal)
            self.powerImage.image = UIImage(systemName: "power", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))?.withTintColor(.systemGray5, renderingMode: .alwaysOriginal)
        } else {
            self.imageView.image = UIImage(systemName: "lightbulb.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))?.withTintColor(colour, renderingMode: .alwaysOriginal)
            self.powerImage.image = UIImage(systemName: "power", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))?.withTintColor(colour, renderingMode: .alwaysOriginal)
        }
        
        self.brightnessSlider.value = Float(state.bri!) / 254.0
        self.brightnessSlider.minimumTrackTintColor = colour
        self.brightnessSlider.thumbTintColor = colour
        
        self.colourPicker.backgroundColor = colour
        self.lightLabel.text = self.light?.name!
    }
    
    @IBAction func brightnessSlider(_ sender: Any) {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(self.setBrightness), userInfo: nil, repeats: false)
    }
}
