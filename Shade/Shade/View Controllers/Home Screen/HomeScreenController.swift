//
//  HomeScreenController.swift
//  Shade
//
//  Created by Charlie While on 25/10/2020.
//

import UIKit
import MediaPlayer

class HomeScreenController: UIViewController {
    @IBOutlet weak var artworkView: UIImageView!
    
    
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
    
    
    private func getArtwork() -> UIImage {
            let mediaItem = MPMediaItem()
            return mediaItem.artwork?.image(at: CGSize(width: 150, height: 150)) ?? UIImage(named: "uwu")! //Fallback for if no music is playing
        }
    
}

