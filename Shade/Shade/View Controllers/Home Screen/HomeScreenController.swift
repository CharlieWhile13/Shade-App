//
//  HomeScreenController.swift
//  Shade
//
//  Created by Charlie While on 25/10/2020.
//

import UIKit

class HomeScreenController: UIViewController {
 
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var dynamicColourView: DynamicColourView!
    
    var containerView = UIView()
    var popupView: LightControlPopover = .fromNib()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if BridgeManager.shared.bridges.count == 0 {
            self.performSegue(withIdentifier: "Shade.ShowPairing", sender: nil)
            return
        }
        
        self.dynamicColourView.setup()
    }
    
    private func clearDefaults() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
    
    @IBAction func unwind( _ seg: UIStoryboardSegue) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.clearDefaults()
        self.setup()
    }
    
    private func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(refreshCollectionView), name: .LightRefactor, object: nil)
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.showsVerticalScrollIndicator = false
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.backgroundColor = .none
        self.collectionView.register(UINib(nibName: "LightCell", bundle: nil), forCellWithReuseIdentifier: "Shade.LightCell")
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(HomeScreenController.showControl))
        longPress.minimumPressDuration = 0.25
        self.collectionView.addGestureRecognizer(longPress)
    }
    
    @objc func showControl(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {
            let touchPoint = longPressGestureRecognizer.location(in: collectionView)
            if let indexPath = collectionView.indexPathForItem(at: touchPoint) {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                /*
            
                let picker = OWOUIColorPickerViewController()
                picker.delegate = self
                picker.supportsAlpha = false
                picker.selectedColor = HueColourTranslator.shared.convertFromHue(LightManager.shared.lights[indexPath.row].state!)
                picker.index = indexPath.row
                
                self.present(picker, animated: true, completion: nil)
 */
                self.showPopup(LightManager.shared.lights[indexPath.row])
            }
        }
    }
    
    @objc func hidePopup() {
        let screenSize = UIScreen.main.bounds.size
          UIView.animate(withDuration: 0.5,
                         delay: 0, usingSpringWithDamping: 1.0,
                         initialSpringVelocity: 1.0,
                         options: .curveEaseInOut, animations: {
            self.containerView.alpha = 0
          }, completion: nil)
    }
    
    private func showPopup(_ light: Light) {
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        containerView.frame = self.view.frame
        self.view.addSubview(containerView)
        
        let tapGesture = UITapGestureRecognizer(target: self,
                            action: #selector(hidePopup))
        containerView.addGestureRecognizer(tapGesture)
        
        containerView.alpha = 0
          UIView.animate(withDuration: 0.5,
                         delay: 0, usingSpringWithDamping: 1.0,
                         initialSpringVelocity: 1.0,
                         options: .curveEaseInOut, animations: {
            self.containerView.alpha = 0.8
          }, completion: nil)
        
        self.popupView.frame = self.view.frame
        self.popupView.lightID = light.id!
        self.view.addSubview(popupView)
    }
}

extension HomeScreenController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
  
        let padding: CGFloat = 15
        let collectionViewSize = collectionView.frame.size.width - padding

        return CGSize(width: collectionViewSize/2, height: collectionViewSize/2)
    }
}

extension HomeScreenController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        LightManager.shared.toggle(LightManager.shared.lights[indexPath.row])
    }
}

extension HomeScreenController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return LightManager.shared.lights.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Shade.LightCell", for: indexPath) as! LightCell
        let light = LightManager.shared.lights[indexPath.row]
        let state = light.state!
        
        var text = ""
        
        text = text + "\(light.name!) \n"
        text = text + "On: \(state.on!) \n XY: \(state.xy!) \n Reachable: \(state.reachable!) \n Bri: \(state.bri!)"

        let colour = HueColourTranslator.shared.convertFromHue(state)
        
        cell.label.text = text
        cell.backgroundColor = colour
        
        return cell
    }
    
    @objc func refreshCollectionView() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
}

extension HomeScreenController: UIColorPickerViewControllerDelegate {
    //Called when the final colour has been picked
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        if viewController is OWOUIColorPickerViewController {
            let funky = viewController as! OWOUIColorPickerViewController
            LightManager.shared.setColour(LightManager.shared.lights[funky.index], viewController.selectedColor)
        }
    }
}
