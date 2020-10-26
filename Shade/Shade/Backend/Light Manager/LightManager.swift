//
//  LightManager.swift
//  Shade
//
//  Created by Charlie While on 25/10/2020.
//

import Foundation
import UIKit

struct Light {
    var id: String?
    var state: LightState?
    var type: String?
    var uniqueid: String?
    var name: String?
    var ip: String?
    var username: String?
    
    init(id: String?, state: LightState?, type: String?, uniqueid: String, name: String?, ip: String?, username: String?) {
        self.id = id
        self.state = state
        self.type = type
        self.uniqueid = uniqueid
        self.name = name
        self.ip = ip
        self.username = username
    }
}

struct LightState {
    var on: Bool?
    var bri: Int?
    var hue: Int?
    var sat: Int?
    var xy: (Float, Float)?
    var ct: Int?
    var reachable: Bool?
    
    init(on: Bool?, bri: Int?, hue: Int?, sat: Int?, xy: (Float, Float)?, ct: Int?, reachable: Bool?) {
        self.on = on
        self.bri = bri
        self.hue = hue
        self.sat = sat
        self.xy = xy
        self.ct = ct
        self.reachable = reachable
    }
}

class LightManager {
    
    static let shared = LightManager()
    var lights = [Light]()
    var timer: Timer?
    
    init() {
        self.grabLightsFromBridge()
    }
    
    @objc public func grabLightsFromBridge() {
        for bridge in BridgeManager.shared.bridges {
            if let url = URL(string: "http://\(bridge.ip!)/api/\(bridge.username!)/lights") {
                NetworkManager.shared.requestWithDict(url: url, method: "GET", headers: nil, jsonbody: nil, completion: { (success, dict) -> Void in
                    if success {
                        for (id, uwu) in dict {
                            if let light = uwu as? [String : Any] {
                                
                                let type = light["type"] as? String ?? "Error"
                                let name = light["name"] as? String ?? "Error"
                                let uniqueID = light["uniqueid"] as? String ?? "Error"
                                
                                let state = light["state"] as! [String : Any]
                                let bri = state["bri"] as! Int
                                let ct = state["ct"] as! Int
                                let hue = state["hue"] as! Int
                                let sat = state["sat"] as! Int
                                let on = state["on"] as! Bool
                                let reachable = state["reachable"] as! Bool
                                let x = Float(truncating: (state["xy"] as! [NSNumber])[0])
                                let y = Float(truncating: (state["xy"] as! [NSNumber])[1])
                                let lightState = LightState(on: on, bri: bri, hue: hue, sat: sat, xy: (x, y), ct: ct, reachable: reachable)
                                
                                let light = Light(id: id, state: lightState, type: type, uniqueid: uniqueID, name: name, ip: bridge.ip!, username: bridge.username!)
                                
                                var found = false
                                for (index, uwu) in self.lights.enumerated() {
                                    if uwu.uniqueid == light.uniqueid {
                                        found = true
                                        self.lights[index] = light
                                    }
                                }
                                
                                if !found {
                                    self.lights.append(light)
                                }
                                
                            }
                        }
                        
                        NotificationCenter.default.post(name: .LightRefactor, object: nil)
                    } else {
                        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.grabLightsFromBridge), userInfo: nil, repeats: false)
                    }
                })
            }
        }
    }
    
    private func sendCommand(_ light: Light, _ command: String, _ index: Int) {
        if let url = URL(string: "http://\(light.ip!)/api/\(light.username!)/lights/\(light.id!)/state") {
            NetworkManager.shared.request(url: url, method: "PUT", headers: nil, jsonbody: command, completion: { (success, dict) -> Void in
                DispatchQueue.main.async {
                    let generator = UINotificationFeedbackGenerator()
                    
                    if success {
                        print(dict)
                        let bridge = "/lights/\(light.id!)/state/"
                        if dict.count == 0 { generator.notificationOccurred(.error); return }
                        
                        for response in dict {
                            if let status = response["success"] as? [String : Any] {
                                let firstKey = Array(status.keys).first!
                                let thingy = firstKey.replacingOccurrences(of: bridge, with: "")
                                
                                switch thingy {
                                case "on": self.lights[index].state?.on = status[firstKey] as? Bool
                                case "hue": self.lights[index].state?.hue = status[firstKey] as? Int
                                case "bri": self.lights[index].state?.bri = status[firstKey] as? Int
                                case "sat": self.lights[index].state?.sat = status[firstKey] as? Int
                                case "ct": self.lights[index].state?.ct = status[firstKey] as? Int
                                case "xy":
                                    let x = (status[firstKey] as! [Float])[0]
                                    let y = (status[firstKey] as! [Float])[1]
                                    self.lights[index].state?.xy = (x, y)
                                    
                                default: generator.notificationOccurred(.error); return
                                }
                            }
                        }
                        
                        generator.notificationOccurred(.success)
                        NotificationCenter.default.post(name: .LightRefactor, object: nil)
                    } else {
                        generator.notificationOccurred(.error)
                    }
                }
            })
        }
    }
    
    public func toggle(_ light: Light, _ index: Int) {
        let body: String!
        if light.state!.on! {
            body = "{\"on\":false}"
        } else {
            body = "{\"on\":true}"
        }
        
        self.sendCommand(light, body, index)
    }
}
