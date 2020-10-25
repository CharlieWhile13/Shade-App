//
//  PairingController.swift
//  Shade
//
//  Created by Charlie While on 24/10/2020.
//

import UIKit
import Network

enum PairingError {
    case wifi
    
    var error: String {
        switch self {
        case.wifi: return "Not on WiFi"
        }
    }
}

class PairingController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var manualLookup: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var searchingStack: UIStackView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var dynamicColourView: DynamicColourView!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setup()
    }
    
    func setup() {
        self.dynamicColourView.setup()
        
        self.continueButton.isHidden = true
        self.errorLabel.isHidden = true
        self.retryButton.isHidden = true
        self.manualLookup.isHidden = true
        
        self.setupNetworkChecking()
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
            if !(path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet)) {
                self.errorLabel.text = PairingError.wifi.error
                self.errorLabel.isHidden = false
                self.retryButton.isHidden = false
                self.searchingStack.isHidden = true
            } else {
                self.errorLabel.isHidden = true
                self.retryButton.isHidden = true
                self.searchingStack.isHidden = false
            }
        }
    }
    
    @IBAction func manualLookup(_ sender: Any) {
        
    }

    @IBAction func continueButton(_ sender: Any) {
    }
    
    @IBAction func retryButton(_ sender: Any) {
    }
    
}
