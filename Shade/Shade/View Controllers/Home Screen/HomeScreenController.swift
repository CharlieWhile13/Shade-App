//
//  HomeScreenController.swift
//  Shade
//
//  Created by Charlie While on 25/10/2020.
//

import UIKit
import Network

class HomeScreenController: UIViewController {
    
    let welcomeText = "Tap on a light to toggle it. Hold a light to change brightness and colour!"
 
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var dynamicColourView: DynamicColourView!
    
    var containerView = UIView()
    var popupView: LightControlPopover = .fromNib()
    var welcomeView: FirstTimeView = .fromNib()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if BridgeManager.shared.bridges.count == 0 {
            self.performSegue(withIdentifier: "Shade.ShowPairing", sender: nil)
            return
        }
        
        if !UserDefaults.standard.bool(forKey: "Shade.HomeWelcome") {
            self.presentWelcomeView()
        }
        
        self.dynamicColourView.setup()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.hidePopup()
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
    
    func setupNetworkChecking() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            self.isOnNetwork(path)
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    func isOnNetwork(_ path: NWPath) {
        DispatchQueue.main.async {
            if path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet) {
                LightManager.shared.grabLightsFromBridge()
            }
        }
    }
    
    private func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(refreshCollectionView), name: .LightRefactor, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hidePopup), name: .HidePopup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showColourPicker(_:)), name: .ShowColourPicker, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideWelcomeView), name: .HideHomeWelcome, object: nil)
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.showsVerticalScrollIndicator = false
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.backgroundColor = .none
        self.collectionView.register(UINib(nibName: "LightCell", bundle: nil), forCellWithReuseIdentifier: "Shade.LightCell")
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(HomeScreenController.showControl))
        longPress.minimumPressDuration = 0.25
        self.collectionView.addGestureRecognizer(longPress)
        
        self.setupNetworkChecking()
    
    }
    
    @objc func showControl(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {
            let touchPoint = longPressGestureRecognizer.location(in: collectionView)
            if let indexPath = collectionView.indexPathForItem(at: touchPoint) {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
         
                self.showPopup(LightManager.shared.lights[indexPath.row])
            }
        }
    }
    
    @objc func hidePopup() {
        let deadBounds = CGRect(x: 0, y: self.view.frame.height, width: self.view.frame.width, height: self.view.frame.height)
        
        UIView.animate(withDuration: 1.0,
                         delay: 0, usingSpringWithDamping: 1.0,
                         initialSpringVelocity: 1.0,
                         options: .curveEaseInOut, animations: {
                            self.containerView.alpha = 0
                            self.popupView.frame = deadBounds
                         }, completion: { (value: Bool) in
                            self.popupView.removeFromSuperview()
                            self.containerView.removeFromSuperview()
          })
    }

    private func showPopup(_ light: Light) {
        self.containerView.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        self.containerView.frame = self.view.frame
        self.containerView.alpha = 0
        self.view.addSubview(containerView)

        let deadBounds = CGRect(x: 0, y: self.view.frame.height, width: self.view.frame.width, height: self.view.frame.height)
                    
        self.popupView.lightID = light.id!
        self.popupView.frame = deadBounds
        self.view.addSubview(popupView)

        UIView.animate(withDuration: 0.5,
                         delay: 0, usingSpringWithDamping: 1.0,
                         initialSpringVelocity: 1.0,
                         options: .curveEaseInOut, animations: {
                            self.containerView.alpha = 0.8
                            self.popupView.frame = self.view.bounds
          }, completion: nil)
        
    }
    
    @objc func showColourPicker(_ notification: NSNotification) {
        let index = notification.userInfo!["index"] as! Int
        let light = LightManager.shared.lights[index]
        
        let picker = OWOUIColorPickerViewController()
        picker.delegate = self
        picker.supportsAlpha = false
        picker.selectedColor = HueColourTranslator.shared.convertFromHue(light.state!)
        picker.index = index
        self.present(picker, animated: true, completion: nil)
    }
    
    @objc func hideWelcomeView() {
        UserDefaults.standard.set(true, forKey: "Shade.HomeWelcome")
        UIView.animate(withDuration: 1.0,
                         delay: 0, usingSpringWithDamping: 1.0,
                         initialSpringVelocity: 1.0,
                         options: .curveEaseInOut, animations: {
                            self.welcomeView.alpha = 0
                            self.containerView.alpha = 0
                         }, completion: { (value: Bool) in
                            self.welcomeView.removeFromSuperview()
                            self.containerView.removeFromSuperview()
          })
    }
    
    private func presentWelcomeView() {
        self.containerView.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        self.containerView.frame = self.view.frame
        self.containerView.alpha = 0
        self.view.addSubview(containerView)
        
        self.welcomeView.text.text = self.welcomeText
        self.welcomeView.alpha = 0.0
        self.welcomeView.frame = self.view.bounds
        self.welcomeView.notification = .HideHomeWelcome
        self.view.addSubview(welcomeView)
        
        UIView.animate(withDuration: 0.5,
                         delay: 0, usingSpringWithDamping: 1.0,
                         initialSpringVelocity: 1.0,
                         options: .curveEaseInOut, animations: {
                            self.welcomeView.alpha = 1.0
                            self.containerView.alpha = 1.0
          }, completion: nil)
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
        
        cell.label.textColor = cell.decideTextColour(colour)
        
        return cell
    }
    
    @objc func refreshCollectionView() {
        
        self.dynamicColourView.colours.removeAll()
        
        for light in LightManager.shared.lights {
            self.dynamicColourView.colours.append(HueColourTranslator.shared.convertFromHue(light.state!).cgColor)
        }
        
        if self.dynamicColourView.colours.count == 1 {
            self.dynamicColourView.colours.append(UIColor.white.cgColor)
        }
    
        self.dynamicColourView.enableRandomColour = false
                
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
}


extension HomeScreenController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        if viewController is OWOUIColorPickerViewController {
            let funky = viewController as! OWOUIColorPickerViewController
            LightManager.shared.setColour(LightManager.shared.lights[funky.index], viewController.selectedColor)
        }
    }
}
