//
//  NotificationInfo.swift
//  Tabble
//
//  Created by 曾德明 on 2023/7/28.
//

import Foundation

struct NotificationInfo: Codable {
    var platform: String = "ios"
    var notifyToken: String
    
    enum CodingKeys: String, CodingKey {
        case platform
        case notifyToken = "notify_token"
    }
}
