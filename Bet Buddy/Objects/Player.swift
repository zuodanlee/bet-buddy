//
//  Player.swift
//  Bet Buddy
//
//  Created by Jordan Lee on 2/2/21.
//

import Foundation
import UIKit

struct Player : Codable {
    var name: String
    var title: String
    var profilePicture: String?
    var playerID: Int?
    var initialBalance: Double?
    var balance: Double?
    var roundBet: Double?
    var isReady: Bool = false
    var outcomeIndex: Int?
    var multiplier: Int?
    var payout: Double?
    
    mutating func calculatePayout() {
        if multiplier == nil {
            multiplier = 1
        }
        
        if outcomeIndex == nil {
            outcomeIndex = 0
        }
        
        var tempPayout = roundBet! * Double(multiplier!)
        if outcomeIndex == 0 {
            tempPayout = -tempPayout
        }
        else if outcomeIndex == 1 {
            tempPayout = 0
        }
        
        payout = tempPayout
    }
}
