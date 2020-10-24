//
//  PairingController.swift
//  Shade
//
//  Created by Charlie While on 24/10/2020.
//

import UIKit

class PairingController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var manualLookup: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var searchingStack: UIStackView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var dynamicColourView: DynamicColourView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setup()
    }
    
    func setup() {
        self.dynamicColourView.setup()
    }
    
    @IBAction func manualLookup(_ sender: Any) {
        
    }

    @IBAction func continueButton(_ sender: Any) {
    }
    
    @IBAction func retryButton(_ sender: Any) {
    }
    
}
