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
    
    init(id: String?, state: LightState? = LightState(), type: String?, uniqueid: String) {
        self.id = id
        self.state = state
        self.type = type
        self.uniqueid = uniqueid
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
    
    func grabLightsFromBridge() {
        for bridge in BridgeManager.shared.bridges {
            if let url = URL(string: "http://\(bridge.ip!)/api/\(bridge.username!)/lights") {
                NetworkManager.shared.requestWithDict(url: url, method: "GET", headers: nil, jsonbody: nil, completion: { (success, dict) -> Void in
                    print(dict)
                })
            }
        }
    }
}
