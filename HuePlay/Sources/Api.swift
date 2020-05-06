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
}

struct TibberGW {
    
    private static let token:String = "INSERT_TOKEN"
    private static let homeId:String = "INSERT_HOMEID"
    private static let groupId:String = "INSERT_GROUPID"
    private static let lightId:String = "INSERT_LIGHTID"
    
    static func sendColor(colorMode:ColorMode, brightness:Int) {
        var lightStateAsText = ""

        switch colorMode {
        case .ct(let m):
            lightStateAsText = "{on:true, bri: \(brightness), ct:\(m)}"
        case .xy(let arr):
            lightStateAsText = "{on:true, bri: \(brightness), xy:[\(arr.map{"\($0)"}.joined(separator: ","))]}"
        }
        
        let mutation = """
        mutation {
          me {
            home(id: "\(homeId)") {
              setLightsState(groupId: "\(groupId)", lights: [{id: "\(lightId)", state: \(lightStateAsText)}]) {
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
        
        print("REQUEST: \(lightStateAsText)")
        
        var request = URLRequest(url: URL(string: "https://app.tibber.com/v4/gql")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["query":mutation], options: [])
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
                print("RESPONSE: \(String(decoding: data, as: UTF8.self))")
            }
        }
        task.resume()
        
    }
}
