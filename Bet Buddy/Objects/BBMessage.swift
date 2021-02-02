//
//  BBMessage.swift
//  Bet Buddy
//
//  Created by Jordan Lee on 1/2/21.
//

import Foundation

struct BBMessage : Codable {
    
    var messageType: String
    var message: String?
    var data: Data?
    
}
