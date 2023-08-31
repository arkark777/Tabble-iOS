//
//  TabbleService.swift
//  Tabble
//
//  Created by 曾德明 on 2023/7/17.
//

import Foundation

class TabbleService: NSObject {
    static let shared = TabbleService()
    
    var serviceUrl: String {
        get {
            if UserDefaults.standard.object(forKey: "serviceUrl") == nil {
                UserDefaults.standard.setValue("", forKey: "serviceUrl")
            }
            return UserDefaults.standard.value(forKey: "serviceUrl") as! String
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "serviceUrl")
        }
    }
    
    var apnsToken: String? {
        get {
            return UserDefaults.standard.value(forKey: "apnsToken") as? String
        }
        set {
            if let token = newValue {
                UserDefaults.standard.setValue(token, forKey: "apnsToken")
            }
        }
    }
}
