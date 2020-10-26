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
    case networkError
    case noneFound
    case bridgeConnectionError
    case bridgeError
    
    var error: String {
        switch self {
        case.wifi: return "Not on WiFi"
        case.networkError: return "Network Error"
        case.noneFound: return "No Bridges Found"
        case.bridgeConnectionError: return "Bridge Connectivity Error"
        case.bridgeError: return "Unknown Error with Bridge"
        }
    }
}

struct DiscoveredBridge {
    var displayName: String!
    var ip: String!
    var paired: Bool!
    var ignore: Bool!
    
    init(displayName: String?, ip: String?, paired: Bool?, ignore: Bool?) {
        self.displayName = displayName
        self.ip = ip
        self.paired = paired
        self.ignore = ignore
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
    
    var discoveredBridges = [DiscoveredBridge]()
    var timer: Timer?
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setup()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        tabBarController?.tabBar.isHidden = false
    }

    
    func setup() {
        self.dynamicColourView.setup()
        
        self.continueButton.isHidden = true
        self.errorLabel.isHidden = true
        self.retryButton.isHidden = true
        self.retryButton.layer.borderColor = UIColor.label.cgColor
        self.continueButton.layer.borderColor = UIColor.label.cgColor
        
        self.setupNetworkChecking()
        
        //Make it transparent
        self.tableView.backgroundColor = .none
        //Removes cells that don't exist
        self.tableView.tableFooterView = UIView()
        //Disable the seperator lines, make it look nice :)
        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        //Disable the scroll indicators
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.showsHorizontalScrollIndicator = false
        //Register the cell from nib
        self.tableView.register(UINib(nibName: "BridgeCell", bundle: nil), forCellReuseIdentifier: "Shade.BridgeCell")
        //Set the delegate/source
        self.tableView.delegate = self
        self.tableView.dataSource = self
        //Bouncy Boi
        self.tableView.alwaysBounceVertical = false
        
        //Set the text view delegate
        self.manualLookup.delegate = self
        //Hide when tapped somewhere else
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.view.addGestureRecognizer(tap)

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
                self.errorWith(PairingError.wifi.error)
                self.manualLookup.isHidden = true
                self.retryButton.isHidden = true
                self.continueButton.isHidden = true
            } else {
                self.loadup()
                self.queryBridges()
            }
        }
    }
    
    func errorWith(_ reason: String) {
        self.errorLabel.text = reason
        self.errorLabel.isHidden = false
        self.retryButton.isHidden = false
        self.searchingStack.isHidden = true
    }
    
    func loadup() {
        self.errorLabel.isHidden = true
        self.retryButton.isHidden = true
        self.searchingStack.isHidden = false
        self.manualLookup.isHidden = false
    }

    @objc func attemptPairing() {
        let body = [
                "devicetype" : "Shade#\(UIDevice.current.name)"
            ]
        let bodyString = NetworkManager.shared.generateStringFromDict(body)
        
        for (index, bridge) in self.discoveredBridges.enumerated() {
            if bridge.paired || bridge.ignore { continue }
            if let url = URL(string: "http://\(bridge.ip!)/api") {
                NetworkManager.shared.request(url: url, method: "POST", headers: nil, jsonbody: bodyString, completion: { (success, dict) -> Void in
                    DispatchQueue.main.async {
                        if success {
                            if dict.count != 1 {
                                self.errorWith(PairingError.bridgeError.error)
                                return
                            }
                            let response = dict.first
                            if let error = response?["error"] as? [String : Any] {
                                if let description = error["description"] {
                                    if description as! String == "link button not pressed" {
                                        let bridge = self.discoveredBridges[index]
                                        self.discoveredBridges[index].displayName = "Press Button : \(bridge.ip!)"
                                        self.tableView.reloadData()
                                        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.attemptPairing), userInfo: nil, repeats: false)
                                    } else {
                                        return
                                    }
                                }
                            } else if let success = response?["success"] as? [String : Any] {
                                if let username = success["username"] as? String {
                                    BridgeManager.shared.addBridge(ip: bridge.ip!, username: username)
                                    let bridge = self.discoveredBridges[index]
                                    self.discoveredBridges[index].displayName = "Paired : \(bridge.ip!)"
                                    self.discoveredBridges[index].paired = true
                                    self.tableView.reloadData()
                                    self.continueButton.isHidden = false
                                } else {
                                    self.errorWith(PairingError.bridgeError.error)
                                    self.timer?.invalidate()
                                    return
                                }
                            }
                        } else {
                            self.discoveredBridges.remove(at: index)
                            var hasFound = false
                            for bridge in self.discoveredBridges {
                                if bridge.paired {
                                    hasFound = true
                                }
                            }
                            
                            self.continueButton.isHidden = !hasFound
                            self.tableView.reloadData()
                        }
                    }
                })
            }
        }
    }
    
    func queryBridges() {
        let surl = "https://discovery.meethue.com"
        
        if let url = URL(string: surl) {
            NetworkManager.shared.request(url: url, method: "GET", headers: nil, jsonbody: nil, completion: { (success, dict) -> Void in
                DispatchQueue.main.async {
                    if success {
                        self.discoveredBridges.removeAll()
                        if dict.count == 0 {
                            self.errorWith(PairingError.noneFound.error)
                            self.manualLookup.isHidden = false
                            return
                        }
                        self.loadup()

                        for bridge in dict {
                            let ip = bridge["internalipaddress"] as? String ?? ""
                            var found = false
                            for bridges in BridgeManager.shared.bridges {
                                if !found {
                                    if bridges.ip == ip {
                                        let bridgeObject = DiscoveredBridge(displayName: "Paired : \(ip)", ip: ip, paired: true, ignore: false)
                                        self.discoveredBridges.append(bridgeObject)
                                        found = true
                                        self.continueButton.isHidden = false
                                    }
                                }
                            }
                            
                            if !found {
                                let bridgeObject = DiscoveredBridge(displayName: ip, ip: ip, paired: false, ignore: false)
                                self.discoveredBridges.append(bridgeObject)
                            }
                        }
                                            
                        self.retryButton.isHidden = false
                        self.tableView.reloadData()
                        self.attemptPairing()
                        
                    } else {
                        self.errorWith(PairingError.networkError.error)
                    }
                }
            })
        }
    }
    
    func createErrorAlert(_ title: String, _ text: String) {
        let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    func manualLookupIP() {
        if manualLookup.text == "" { return }
        let text = manualLookup.text!
        if let _ = URL(string: "http://\(text)/api" ) {
            var isHad = false
            for bridge in self.discoveredBridges {
                if bridge.ip == text {
                    
                    isHad = true
                }
            }
            for bridge in BridgeManager.shared.bridges {
                if bridge.ip == text {
                    isHad = true
                }
            }
            
            if isHad {
                self.createErrorAlert("Already Found", "This Bridge has already been discovered")
                return
            }
            
            let bridgeObject = DiscoveredBridge(displayName: text, ip: text, paired: false, ignore: false)
            self.discoveredBridges.append(bridgeObject)
            self.attemptPairing()
        } else {
            self.createErrorAlert("Invalid IP", "This isn't a valid address to a Bridge")
            return
        }
    }

    @IBAction func continueButton(_ sender: Any) {
        self.timer?.invalidate()
        
        DispatchQueue.global(qos: .userInitiated).async {
            LightManager.shared.grabLightsFromBridge()
        }
        
        self.performSegue(withIdentifier: "Shade.ReturnFromPairing", sender: self)
    }
    
    @IBAction func retryButton(_ sender: Any) {
        self.timer?.invalidate()
        self.queryBridges()
    }
    
}

extension PairingController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Make it invisible when you press it
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension PairingController : UITableViewDataSource {

    //This is just meant to be
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.discoveredBridges.count
    }
    
    //This is what handles all the images and text etc, using the class mainScreenTableCells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Shade.BridgeCell", for: indexPath) as! BridgeCell
        
        cell.label.text = self.discoveredBridges[indexPath.row].displayName
        cell.hueImageView.image = UIImage(named: "BridgeIcon")
        cell.minHeight = 50
        
        return cell
    }
}

extension PairingController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()// dismiss keyboard
        self.manualLookupIP()
        return true
    }
    
    @objc func handleTap() {
        self.manualLookup.resignFirstResponder()
    }
}
