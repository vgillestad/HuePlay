//
//  Api.swift
//  HuePlay
//
//  Created by Vegard Gillestad on 06/05/2020.
//  Copyright © 2020 Tibber. All rights reserved.
//

import Foundation

enum ColorMode {
    case ct(Int)
    case xy([Double])
    case hs(hue:Int,sat:Int)
}

struct TibberGW {
    
    private static let TOKEN:String = ""
    private static let HOME_ID:String = "42fbc40d-9553-47e0-bd7c-a54a2d5317e3"
    private static let LIGHT_ID:String = "hue device#a6b3d7e3-348d-43d0-8080-05770b7f3826#1"
    
    static func sendColor(colorMode:ColorMode, brightness:Int) {
        var lightState = ""

        switch colorMode {
        case .ct(let m):
            lightState = "{on:true, brightness: \(Double(brightness)/255), ct:\(m)}"
        case .xy(let arr):
            lightState = "{on:true, brightness: \(Double(brightness)/255), xy:[\(arr.map{"\($0)"}.joined(separator: ","))]}"
        case .hs(let hue, let sat):
            lightState = "{on:true, brightness: \(Double(brightness)/255), hue:\(hue), sat:\(sat)}"
            fatalError("not supported")
        }
        
        let mutation = """
        mutation {
          me {
            home(id: "\(HOME_ID)") {
              setLightsState(lights: [{id: "\(LIGHT_ID)", state: \(lightState)}]) {
                error {
                  statusCode
                  title
                  message
                }
              }
            }
          }
        }
        """
        
        print("REQUEST: \(lightState)")
        
        var request = URLRequest(url: URL(string: "https://app.tibber.com/v4/gql")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["query":mutation], options: [])
        request.setValue(TOKEN, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
                print("RESPONSE: \(String(decoding: data, as: UTF8.self))")
            }
        }
        task.resume()
        
    }
}
