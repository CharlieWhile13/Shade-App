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
    var id: String!
    var paired: Bool!
    
    init(displayName: String?, ip: String?, id: String?, paired: Bool?) {
        self.displayName = displayName
        self.ip = ip
        self.id = id
        self.paired = paired
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
        //Roundy Corners
        self.tableView.layer.masksToBounds = true
        self.tableView.layer.cornerRadius = 15
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
            } else {
                self.loadup()
                
                DispatchQueue.global(qos: .userInitiated).async {
                    self.queryBridges()
                }
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
    }
    
    func attemptPairing() {
        let body = [
                "devicetype" : "Shade#\(UIDevice.current.name)"
            ]
        let bodyString = NetworkManager.shared.generateStringFromDict(body)
        
        for (index, bridge) in self.discoveredBridges.enumerated() {
            if bridge.paired { continue }
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
                                } else {
                                    self.errorWith(PairingError.bridgeError.error)
                                    return
                                }
                            }
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
                            return
                        }
                        self.loadup()

                        for bridge in dict {
                            let id = bridge["id"] as? String ?? ""
                            let ip = bridge["internalipaddress"] as? String ?? ""
                            let bridgeObject = DiscoveredBridge(displayName: ip, ip: ip, id: id, paired: false)
                            self.discoveredBridges.append(bridgeObject)
                        }
                        
                        self.tableView.reloadData()
                        self.attemptPairing()
                        
                    } else {
                        self.errorWith(PairingError.networkError.error)
                    }
                }
            })
        }
    }
    
    @IBAction func manualLookup(_ sender: Any) {
        
    }

    @IBAction func continueButton(_ sender: Any) {
    }
    
    @IBAction func retryButton(_ sender: Any) {
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

        return cell
    }
}
