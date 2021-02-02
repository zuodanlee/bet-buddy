//
//  BlackjackOutcome.swift
//  Bet Buddy
//
//  Created by Jordan Lee on 2/2/21.
//

import Foundation

struct BlackjackOutcome : Codable {
    var playerID: Int
    var roundBet: Double
    var didBankerWin: Bool
    var multiplier: Int
    var payout: Double?
    
    func calculatePayout() -> Double {
        var tempPayout = roundBet * Double(multiplier)
        if didBankerWin {
            print(tempPayout)
            tempPayout = -tempPayout
            print(tempPayout)
        }
        
        return tempPayout
    }
}
