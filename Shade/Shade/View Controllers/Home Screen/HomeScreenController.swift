//
//  HomeScreenController.swift
//  Shade
//
//  Created by Charlie While on 25/10/2020.
//

import UIKit

class HomeScreenController: UIViewController {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if BridgeManager.shared.bridges.count == 0 {
            self.performSegue(withIdentifier: "Shade.ShowPairing", sender: nil)
            return
        }
        
        print(LightManager.shared.grabLightsFromBridge())
    }
    
    @IBAction func unwind( _ seg: UIStoryboardSegue) {
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    
    }
    
}
