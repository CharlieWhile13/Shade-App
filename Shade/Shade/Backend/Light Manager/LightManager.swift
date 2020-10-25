//
//  LightManager.swift
//  Shade
//
//  Created by Charlie While on 25/10/2020.
//
import Foundation


struct Light {
    var id: String?
    var state: LightState?
    var type: String?
    var uniqueid: String?
    var name: String?
    
    init(id: String?, state: LightState? = LightState(), type: String?, uniqueid: String, name: String?) {
        self.id = id
        self.state = state
        self.type = type
        self.uniqueid = uniqueid
        self.name = name
    }
}

struct LightState {
    var on: Bool?
    var bri: Int?
    var hue: Int?
    var sat: Int?
    var xy: [Int]?
    var ct: Int?
}

class LightManager {
    
    static let shared = LightManager()
    var lights = [Light]()
    
    private func alreadyHas(_ uniqueID: String) -> Bool {
        let knownLights = UserDefaults.standard.value(forKey: "Lights") as? [[String : String]] ?? [[String : String]]()
        for knownLight in knownLights {
            if knownLight["uniqueID"] == uniqueID {
                return true
            }
        }
        return false
    }
    
    private func populateLights() {
        self.lights.removeAll()
        let knownLights = UserDefaults.standard.value(forKey: "Lights") as? [[String : String]] ?? [[String : String]]()
        for light in knownLights {
            let type = light["type"]!
            let name = light["name"]!
            let uniqueID = light["uniqueid"]!
            let id = light["id"]!
            
            let lightObject = Light(id: id, state: nil, type: type, uniqueid: uniqueID, name: name)
            self.lights.append(lightObject)
        }
    }
    
    init() {
        self.populateLights()
    }
    
    public func grabLightsFromBridge() {
        for bridge in BridgeManager.shared.bridges {
            if let url = URL(string: "http://\(bridge.ip!)/api/\(bridge.username!)/lights") {
                NetworkManager.shared.requestWithDict(url: url, method: "GET", headers: nil, jsonbody: nil, completion: { (success, dict) -> Void in
                    if success {
                        for (id, uwu) in dict {
                            if let light = uwu as? [String : Any] {
                                var knownLights = UserDefaults.standard.value(forKey: "Lights") as? [[String : String]] ?? [[String : String]]()
                                
                                let type = light["type"] as? String ?? "Error"
                                let name = light["name"] as? String ?? "Error"
                                let uniqueID = light["uniqueid"] as? String ?? "Error"

                                if !self.alreadyHas(uniqueID) {
                                    let newLight: [String : String] = [
                                        "type" : type,
                                        "name" : name,
                                        "uniqueid" : uniqueID,
                                        "id" : id
                                    ]
                                    knownLights.append(newLight)
                                    UserDefaults.standard.setValue(knownLights, forKey: "Lights")
                                }
                            }
                        }
                        
                        self.populateLights()
                    }
                })
            }
        }
    }
}
